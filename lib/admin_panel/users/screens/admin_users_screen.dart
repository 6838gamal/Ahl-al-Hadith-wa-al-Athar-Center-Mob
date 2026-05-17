import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../shared/layout/admin_layout.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';

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
    final allUsers = MockDataService.instance.allUsers;
    final filtered = allUsers.where((u) => u.effectiveName.contains(_searchQuery) || u.username.contains(_searchQuery)).toList();

    return AdminLayout(
      currentPath: '/admin/users',
      child: Column(
        children: [
          _buildHeader(allUsers),
          _buildSearchBar(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [Tab(text: 'الكل'), Tab(text: 'نشطون'), Tab(text: 'معلقون')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UsersList(users: filtered),
                _UsersList(users: filtered.where((u) => u.status == 'active').toList()),
                _UsersList(users: filtered.where((u) => u.status == 'pending').toList(), showApprove: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<UserModel> users) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('إدارة المستخدمين', style: AppTextStyles.h2),
              Text('${users.length} مستخدم مسجل', style: AppTextStyles.bodySmall),
            ]),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('إضافة مستخدم'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'بحث بالاسم أو اسم المستخدم...',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        ),
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  final List<UserModel> users;
  final bool showApprove;
  const _UsersList({required this.users, this.showApprove = false});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return Center(child: Text('لا يوجد مستخدمون', style: AppTextStyles.h3.copyWith(color: AppColors.textMuted)));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _UserRow(user: users[i], showApprove: showApprove),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;
  final bool showApprove;
  const _UserRow({required this.user, required this.showApprove});

  @override
  Widget build(BuildContext context) {
    final statusColor = {
      'active': AppColors.success,
      'pending': AppColors.warning,
      'suspended': AppColors.error,
      'banned': AppColors.error,
    }[user.status] ?? AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          UserAvatar(name: user.effectiveName, size: 44, showOnline: true, isOnline: user.isOnline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(user.effectiveName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(user.roleLabel, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  ),
                ]),
                Text('@${user.username} · ${user.academicId}', style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(_statusLabel(user.status), style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {},
            itemBuilder: (_) => [
              if (showApprove) ...[
                const PopupMenuItem(value: 'approve', child: Text('✅ قبول')),
                const PopupMenuItem(value: 'reject', child: Text('❌ رفض')),
              ],
              const PopupMenuItem(value: 'edit', child: Text('✏️ تعديل')),
              const PopupMenuItem(value: 'ban', child: Text('🚫 حظر')),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'active': return 'نشط';
      case 'pending': return 'معلق';
      case 'suspended': return 'موقوف';
      case 'banned': return 'محظور';
      default: return s;
    }
  }
}
