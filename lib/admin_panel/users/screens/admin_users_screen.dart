import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../shared/layout/admin_layout.dart';

// ─── Provider ─────────────────────────────────────────────────
final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AsyncValue<List<UserModel>>>((ref) => AdminUsersNotifier());

class AdminUsersNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final ApiClient _api = ApiClient.instance;
  String _searchQuery = '';
  String? _statusFilter;

  AdminUsersNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load({String? q, String? status}) async {
    _searchQuery = q ?? _searchQuery;
    _statusFilter = status ?? _statusFilter;
    try {
      final params = <String, dynamic>{};
      if (_searchQuery.isNotEmpty) params['q'] = _searchQuery;
      if (_statusFilter != null) params['status'] = _statusFilter;
      final res = await _api.get(ApiEndpoints.adminUsers, queryParameters: params.isEmpty ? null : params);
      final list = (res.data as List).map((j) => UserModel.fromJson(j as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<bool> approveUser(String userId) async {
    try {
      await _api.post(ApiEndpoints.approveUser(userId));
      state.whenData((list) => state = AsyncValue.data(
          list.map((u) => u.id == userId ? u.copyWith(status: 'active') : u).toList()));
      return true;
    } catch (_) { return false; }
  }

  Future<bool> rejectUser(String userId) async {
    try {
      await _api.post(ApiEndpoints.rejectUser(userId));
      state.whenData((list) => state = AsyncValue.data(list.where((u) => u.id != userId).toList()));
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final res = await _api.patch(ApiEndpoints.adminUserById(userId), data: updates);
      final updated = UserModel.fromJson(res.data as Map<String, dynamic>);
      state.whenData((list) => state = AsyncValue.data(list.map((u) => u.id == userId ? updated : u).toList()));
      return true;
    } catch (_) { return false; }
  }
}

// ─── Screen ───────────────────────────────────────────────────
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final filters = [null, 'active', 'pending'];
    ref.read(adminUsersProvider.notifier).load(status: filters[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    return AdminLayout(
      currentPath: '/admin/users',
      child: Column(children: [
        _buildHeader(usersAsync),
        _buildSearchBar(),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary, indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'الكل'), Tab(text: 'نشطون'), Tab(text: 'معلقون')],
        ),
        Expanded(child: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('خطأ في التحميل', style: AppTextStyles.body),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => ref.read(adminUsersProvider.notifier).load(), child: const Text('إعادة المحاولة')),
          ])),
          data: (users) => TabBarView(
            controller: _tabController,
            children: [
              _UsersList(users: users, onApprove: _approveUser, onReject: _rejectUser, onEdit: _editUser),
              _UsersList(users: users.where((u) => u.status == 'active').toList(), onApprove: _approveUser, onReject: _rejectUser, onEdit: _editUser),
              _UsersList(users: users.where((u) => u.status == 'pending').toList(), onApprove: _approveUser, onReject: _rejectUser, onEdit: _editUser, showApprove: true),
            ],
          ),
        )),
      ]),
    );
  }

  Widget _buildHeader(AsyncValue<List<UserModel>> usersAsync) => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('إدارة المستخدمين', style: AppTextStyles.h2),
        if (usersAsync.value != null) Text('${usersAsync.value!.length} مستخدم', style: AppTextStyles.bodySmall),
      ])),
      ElevatedButton.icon(
        onPressed: () => ref.read(adminUsersProvider.notifier).load(),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('تحديث'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      ),
    ]),
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'بحث بالاسم أو الرقم الأكاديمي...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); ref.read(adminUsersProvider.notifier).load(q: ''); })
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (q) => ref.read(adminUsersProvider.notifier).load(q: q),
    ),
  );

  Future<void> _approveUser(String userId) async {
    final ok = await ref.read(adminUsersProvider.notifier).approveUser(userId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم قبول المستخدم بنجاح' : 'فشل في قبول المستخدم'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _rejectUser(String userId) async {
    final ok = await ref.read(adminUsersProvider.notifier).rejectUser(userId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم رفض المستخدم' : 'فشل في رفض المستخدم'),
      backgroundColor: ok ? AppColors.error : AppColors.error,
    ));
  }

  void _editUser(UserModel user) {
    String selectedStatus = user.status;
    String selectedRole = user.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تعديل: ${user.effectiveName}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Gender & Academic ID info row (read-only)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Icon(user.gender == 'female' ? Icons.female_rounded : Icons.male_rounded,
                    color: user.gender == 'female' ? Colors.pink : AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(user.gender == 'female' ? 'أنثى' : 'ذكر', style: AppTextStyles.caption),
                const SizedBox(width: 16),
                const Icon(Icons.numbers_rounded, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 4),
                Text(user.academicId, style: AppTextStyles.caption),
              ]),
            ),
            DropdownButtonFormField<String>(
              value: selectedStatus, decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('نشط')),
                DropdownMenuItem(value: 'pending', child: Text('معلق')),
                DropdownMenuItem(value: 'suspended', child: Text('موقوف')),
                DropdownMenuItem(value: 'banned', child: Text('محظور')),
              ],
              onChanged: (v) => setD(() => selectedStatus = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRole, decoration: const InputDecoration(labelText: 'الرتبة', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'male_student', child: Text('طالب')),
                DropdownMenuItem(value: 'female_student', child: Text('طالبة')),
                DropdownMenuItem(value: 'sheikh', child: Text('شيخ')),
                DropdownMenuItem(value: 'moderator', child: Text('مشرف')),
              ],
              onChanged: (v) => setD(() => selectedRole = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await ref.read(adminUsersProvider.notifier).updateUser(user.id, {'status': selectedStatus, 'role': selectedRole});
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'تم الحفظ بنجاح' : 'فشل في الحفظ'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ));
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )),
    );
  }
}

class _UsersList extends StatelessWidget {
  final List<UserModel> users;
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String) onReject;
  final void Function(UserModel) onEdit;
  final bool showApprove;
  const _UsersList({required this.users, required this.onApprove, required this.onReject, required this.onEdit, this.showApprove = false});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textMuted),
      const SizedBox(height: 16),
      Text('لا يوجد مستخدمون', style: AppTextStyles.h3.copyWith(color: AppColors.textMuted)),
    ]));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) => _UserCard(user: users[i], onApprove: onApprove, onReject: onReject, onEdit: onEdit, showApprove: showApprove || users[i].status == 'pending'),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String) onReject;
  final void Function(UserModel) onEdit;
  final bool showApprove;
  const _UserCard({required this.user, required this.onApprove, required this.onReject, required this.onEdit, required this.showApprove});

  Color get _statusColor => switch (user.status) {
    'active' => AppColors.success, 'pending' => AppColors.warning,
    'suspended' => AppColors.error, _ => AppColors.textMuted,
  };

  String get _statusLabel => switch (user.status) {
    'active' => 'نشط', 'pending' => 'معلق', 'suspended' => 'موقوف', _ => 'محظور',
  };

  @override
  Widget build(BuildContext context) {
    final isFemale = user.gender == 'female';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          UserAvatar(name: user.effectiveName, avatarUrl: user.avatarUrl, size: 48, showOnline: user.isOnline, isOnline: user.isOnline),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(user.effectiveName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
              // Gender badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: (isFemale ? Colors.pink : AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isFemale ? Icons.female_rounded : Icons.male_rounded,
                      size: 12, color: isFemale ? Colors.pink : AppColors.primary),
                  const SizedBox(width: 2),
                  Text(isFemale ? 'أنثى' : 'ذكر',
                      style: TextStyle(fontSize: 10, color: isFemale ? Colors.pink : AppColors.primary, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            Text('@${user.username} · ${user.academicId}', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w600))),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(user.roleLabel, style: const TextStyle(color: AppColors.primary, fontSize: 10))),
            ]),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            onSelected: (v) {
              if (v == 'approve') onApprove(user.id);
              else if (v == 'reject') onReject(user.id);
              else if (v == 'edit') onEdit(user);
            },
            itemBuilder: (_) => [
              if (showApprove) ...[
                const PopupMenuItem(value: 'approve', child: Row(children: [Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18), SizedBox(width: 8), Text('قبول')])),
                const PopupMenuItem(value: 'reject', child: Row(children: [Icon(Icons.cancel_rounded, color: AppColors.error, size: 18), SizedBox(width: 8), Text('رفض')])),
              ],
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, color: AppColors.primary, size: 18), SizedBox(width: 8), Text('تعديل')])),
            ],
          ),
        ]),
      ),
    );
  }
}
