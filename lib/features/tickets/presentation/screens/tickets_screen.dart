import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

enum TicketStatus { open, inProgress, resolved, closed }
enum TicketPriority { low, medium, high, urgent }

class TicketModel {
  final String id, title, body, submitterId, submitterName;
  final TicketStatus status;
  final TicketPriority priority;
  final String? assigneeId, assigneeName;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const TicketModel({required this.id, required this.title, required this.body, required this.submitterId, required this.submitterName, required this.status, required this.priority, this.assigneeId, this.assigneeName, required this.createdAt, this.resolvedAt});
}

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _tickets = [
    TicketModel(id: 't1', title: 'استفسار عن موعد الدرس', body: 'هل سيُقام الدرس الأسبوعي يوم الجمعة؟', submitterId: 'u4', submitterName: 'علي محمد', status: TicketStatus.open, priority: TicketPriority.medium, createdAt: DateTime(2025, 5, 10)),
    TicketModel(id: 't2', title: 'مشكلة في تسجيل الدخول', body: 'لا أستطيع الدخول منذ يومين', submitterId: 'u5', submitterName: 'فاطمة الأنصاري', status: TicketStatus.inProgress, priority: TicketPriority.high, assigneeId: 'u3', assigneeName: 'سارة المشرفة', createdAt: DateTime(2025, 5, 9)),
    TicketModel(id: 't3', title: 'طلب شهادة إتمام دورة', body: 'أطلب شهادة لدورة مصطلح الحديث', submitterId: 'u6', submitterName: 'عمر خالد', status: TicketStatus.resolved, priority: TicketPriority.low, createdAt: DateTime(2025, 5, 5), resolvedAt: DateTime(2025, 5, 7)),
    TicketModel(id: 't4', title: 'خطأ في رفع الملف', body: 'عند محاولة رفع ملف PDF يظهر خطأ', submitterId: 'u4', submitterName: 'علي محمد', status: TicketStatus.open, priority: TicketPriority.urgent, createdAt: DateTime(2025, 5, 11)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صندوق التذاكر'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.secondary,
          tabs: const [Tab(text: 'مفتوحة'), Tab(text: 'قيد المعالجة'), Tab(text: 'مُغلقة')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TicketsList(tickets: _tickets.where((t) => t.status == TicketStatus.open).toList()),
          _TicketsList(tickets: _tickets.where((t) => t.status == TicketStatus.inProgress).toList()),
          _TicketsList(tickets: _tickets.where((t) => t.status == TicketStatus.resolved || t.status == TicketStatus.closed).toList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('تذكرة جديدة', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showNewTicketDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewTicketSheet(),
    );
  }
}

class _TicketsList extends StatelessWidget {
  final List<TicketModel> tickets;
  const _TicketsList({required this.tickets});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('لا توجد تذاكر', style: AppTextStyles.h3.copyWith(color: AppColors.textMuted)),
        ],
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _TicketCard(ticket: tickets[i]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final priorityData = {
      TicketPriority.low: ('منخفضة', AppColors.success),
      TicketPriority.medium: ('متوسطة', AppColors.warning),
      TicketPriority.high: ('عالية', AppColors.error),
      TicketPriority.urgent: ('عاجل', const Color(0xFF9B2226)),
    };
    final pd = priorityData[ticket.priority]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(ticket.title, style: AppTextStyles.h3.copyWith(fontSize: 15))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: pd.$2.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: pd.$2)), child: Text(pd.$1, style: AppTextStyles.caption.copyWith(color: pd.$2, fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 8),
            Text(ticket.body, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(ticket.submitterName, style: AppTextStyles.caption),
                if (ticket.assigneeName != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.assignment_ind_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(ticket.assigneeName!, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ],
                const Spacer(),
                Text('${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewTicketSheet extends StatelessWidget {
  const _NewTicketSheet();

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('تذكرة جديدة', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان التذكرة', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: bodyController, maxLines: 3, decoration: const InputDecoration(labelText: 'تفاصيل المشكلة', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إرسال التذكرة')),
          ],
        ),
      ),
    );
  }
}
