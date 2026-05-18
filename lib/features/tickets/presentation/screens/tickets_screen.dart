import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/extensions/datetime_extensions.dart';

// ─── Category helpers ──────────────────────────────────────────

const _categoryLabels = {
  'question': 'سؤال',
  'fatwa': 'فتوى',
  'complaint': 'شكوى',
  'suggestion': 'اقتراح',
};

const _categoryIcons = {
  'question': Icons.help_outline_rounded,
  'fatwa': Icons.menu_book_rounded,
  'complaint': Icons.report_outlined,
  'suggestion': Icons.lightbulb_outline_rounded,
};

const _categoryColors = {
  'question': AppColors.primary,
  'fatwa': AppColors.success,
  'complaint': AppColors.error,
  'suggestion': AppColors.warning,
};

// ─── Models ───────────────────────────────────────────────────

class TicketData {
  final String id, title, body, submitterId;
  final String? submitterName, assigneeId, assigneeName;
  final String status, priority;
  final String ticketCategory;
  final List<TicketReplyData> replies;
  final DateTime createdAt, updatedAt;
  final DateTime? resolvedAt;

  const TicketData({
    required this.id, required this.title, required this.body,
    required this.submitterId, this.submitterName, this.assigneeId, this.assigneeName,
    required this.status, required this.priority, this.ticketCategory = 'question',
    this.replies = const [],
    required this.createdAt, required this.updatedAt, this.resolvedAt,
  });

  factory TicketData.fromJson(Map<String, dynamic> j) => TicketData(
    id: j['id'] as String, title: j['title'] as String, body: j['body'] as String,
    submitterId: j['submitter_id'] as String,
    submitterName: (j['submitter'] as Map?)?['display_name'] as String? ?? (j['submitter'] as Map?)?['username'] as String?,
    assigneeId: j['assignee_id'] as String?,
    assigneeName: (j['assignee'] as Map?)?['display_name'] as String? ?? (j['assignee'] as Map?)?['username'] as String?,
    status: j['status'] as String, priority: j['priority'] as String,
    ticketCategory: j['ticket_category'] as String? ?? 'question',
    replies: (j['replies'] as List? ?? []).map((r) => TicketReplyData.fromJson(r as Map<String, dynamic>)).toList(),
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
    resolvedAt: j['resolved_at'] != null ? DateTime.tryParse(j['resolved_at'] as String) : null,
  );
}

class TicketReplyData {
  final String id, authorId, content;
  final String? authorName;
  final bool isInternal;
  final DateTime createdAt;
  const TicketReplyData({required this.id, required this.authorId, required this.content, this.authorName, required this.isInternal, required this.createdAt});
  factory TicketReplyData.fromJson(Map<String, dynamic> j) => TicketReplyData(
    id: j['id'] as String, authorId: j['author_id'] as String, content: j['content'] as String,
    authorName: (j['author'] as Map?)?['display_name'] as String? ?? (j['author'] as Map?)?['username'] as String?,
    isInternal: j['is_internal'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

// ─── Provider ─────────────────────────────────────────────────

final ticketsProvider =
    StateNotifierProvider<TicketsNotifier, AsyncValue<List<TicketData>>>((ref) {
  ref.watch(currentUserProvider);
  return TicketsNotifier();
});

class TicketsNotifier extends StateNotifier<AsyncValue<List<TicketData>>> {
  final ApiClient _api = ApiClient.instance;
  TicketsNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load({String? status}) async {
    try {
      final res = await _api.get(ApiEndpoints.tickets, queryParameters: status != null ? {'status': status} : null);
      final list = (res.data as List).map((j) => TicketData.fromJson(j as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<bool> createTicket(String title, String body, String priority, String category) async {
    try {
      final res = await _api.post(ApiEndpoints.tickets, data: {'title': title, 'body': body, 'priority': priority, 'ticket_category': category});
      final newTicket = TicketData.fromJson(res.data as Map<String, dynamic>);
      state.whenData((list) => state = AsyncValue.data([newTicket, ...list]));
      return true;
    } catch (_) { return false; }
  }

  Future<bool> addReply(String ticketId, String content) async {
    try {
      await _api.post(ApiEndpoints.ticketReplies(ticketId), data: {'content': content, 'is_internal': false});
      await load();
      return true;
    } catch (_) { return false; }
  }
}

// ─── Screen ───────────────────────────────────────────────────

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});
  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاستفسارات والدعم'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.secondary,
          tabs: const [Tab(text: 'مفتوحة'), Tab(text: 'قيد المعالجة'), Tab(text: 'مُغلقة')],
        ),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('خطأ في التحميل', style: AppTextStyles.body),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => ref.read(ticketsProvider.notifier).load(), child: const Text('إعادة المحاولة')),
        ])),
        data: (tickets) => TabBarView(
          controller: _tabController,
          children: [
            _TicketsList(tickets: tickets.where((t) => t.status == 'open').toList(), onRefresh: () => ref.read(ticketsProvider.notifier).load()),
            _TicketsList(tickets: tickets.where((t) => t.status == 'in_progress').toList(), onRefresh: () => ref.read(ticketsProvider.notifier).load()),
            _TicketsList(tickets: tickets.where((t) => t.status == 'resolved' || t.status == 'closed').toList(), onRefresh: () => ref.read(ticketsProvider.notifier).load()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('استفسار جديد', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showNewTicketDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String priority = 'medium';
    String category = 'question';
    bool loading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('استفسار جديد', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text('اختر نوع الاستفسار وأدخل التفاصيل', style: AppTextStyles.caption),
              const SizedBox(height: 16),
              // Category selector
              _CategorySelector(
                selected: category,
                onChanged: (v) => setState(() => category = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'الموضوع', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'التفاصيل', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'أهمية الاستفسار', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                  DropdownMenuItem(value: 'medium', child: Text('متوسطة')),
                  DropdownMenuItem(value: 'high', child: Text('عالية')),
                  DropdownMenuItem(value: 'urgent', child: Text('عاجلة')),
                ],
                onChanged: (v) => setState(() => priority = v!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: loading ? null : () async {
                  if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
                  setState(() => loading = true);
                  final ok = await ref.read(ticketsProvider.notifier).createTicket(titleCtrl.text.trim(), bodyCtrl.text.trim(), priority, category);
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  if (ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال استفسارك بنجاح'), backgroundColor: AppColors.success));
                },
                child: loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('إرسال', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      )),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _CategorySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final categories = ['question', 'fatwa', 'complaint', 'suggestion'];
    return Row(
      children: categories.map((cat) {
        final isSelected = selected == cat;
        final color = _categoryColors[cat] ?? AppColors.primary;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : AppColors.surface,
                border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Icon(_categoryIcons[cat]!, color: isSelected ? color : AppColors.textMuted, size: 20),
                const SizedBox(height: 4),
                Text(_categoryLabels[cat]!, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? color : AppColors.textSecondary), textAlign: TextAlign.center),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TicketsList extends StatelessWidget {
  final List<TicketData> tickets;
  final Future<void> Function() onRefresh;
  const _TicketsList({required this.tickets, required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text('لا توجد استفسارات', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (_, i) => _TicketCard(ticket: tickets[i]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketData ticket;
  const _TicketCard({required this.ticket});

  Color get _statusColor => switch (ticket.status) {
    'open' => AppColors.primary,
    'in_progress' => AppColors.warning,
    'resolved' => AppColors.success,
    _ => AppColors.textMuted,
  };

  Color get _priorityColor => switch (ticket.priority) {
    'urgent' => AppColors.error,
    'high' => AppColors.warning,
    'medium' => AppColors.primary,
    _ => AppColors.textMuted,
  };

  String get _statusLabel => switch (ticket.status) {
    'open' => 'مفتوح',
    'in_progress' => 'قيد المعالجة',
    'resolved' => 'تمت الإجابة',
    _ => 'مُغلق',
  };

  String get _priorityLabel => switch (ticket.priority) {
    'urgent' => 'عاجلة',
    'high' => 'عالية',
    'medium' => 'متوسطة',
    _ => 'منخفضة',
  };

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColors[ticket.ticketCategory] ?? AppColors.primary;
    final catIcon = _categoryIcons[ticket.ticketCategory] ?? Icons.help_outline_rounded;
    final catLabel = _categoryLabels[ticket.ticketCategory] ?? 'استفسار';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(catIcon, size: 12, color: catColor),
                const SizedBox(width: 4),
                Text(catLabel, style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 8),
          Text(ticket.title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(ticket.body, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(_priorityLabel, style: TextStyle(color: _priorityColor, fontSize: 10))),
            const Spacer(),
            if (ticket.replies.isNotEmpty) ...[
              Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${ticket.replies.length}', style: AppTextStyles.caption),
              const SizedBox(width: 12),
            ],
            Text(ticket.createdAt.chatTime, style: AppTextStyles.caption),
          ]),
        ]),
      ),
    );
  }
}
