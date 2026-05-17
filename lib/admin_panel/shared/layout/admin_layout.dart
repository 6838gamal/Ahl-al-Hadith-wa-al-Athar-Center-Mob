import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../shared/widgets/user_avatar.dart';

class AdminLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;
  const AdminLayout({super.key, required this.child, required this.currentPath});

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isWide = MediaQuery.of(context).size.width > 1000;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: isWide ? null : _buildMobileAppBar(user?.effectiveName ?? ''),
        drawer: isWide ? null : _buildDrawer(),
        body: isWide
            ? Row(children: [_buildSidebar(), Expanded(child: widget.child)])
            : widget.child,
      ),
    );
  }

  AppBar _buildMobileAppBar(String name) => AppBar(
        backgroundColor: AppColors.adminPrimary,
        title: Text('لوحة التحكم', style: AppTextStyles.appBarTitle),
        actions: [IconButton(icon: const Icon(Icons.person_outline, color: Colors.white), onPressed: () {})],
      );

  Widget _buildDrawer() => Drawer(
        child: Container(color: AppColors.adminSidebar, child: _buildSidebarContent()),
      );

  Widget _buildSidebar() {
    final width = _sidebarCollapsed ? 68.0 : 240.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      color: AppColors.adminSidebar,
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    final user = ref.watch(currentUserProvider);
    final items = _navItems;

    return Column(
      children: [
        _buildSidebarHeader(user?.effectiveName ?? 'مدير'),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: items.map((item) => _NavItem(
              icon: item.icon,
              label: item.label,
              path: item.path,
              currentPath: widget.currentPath,
              collapsed: _sidebarCollapsed,
              onTap: () => context.go(item.path),
            )).toList(),
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        _buildSidebarFooter(),
      ],
    );
  }

  Widget _buildSidebarHeader(String name) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(name: name, size: 40, backgroundColor: AppColors.adminAccent.withOpacity(0.3)),
          if (!_sidebarCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('مدير النظام', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                ],
              ),
            ),
          ],
          IconButton(
            icon: Icon(_sidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded, color: Colors.white60, size: 20),
            onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _NavItem(
        icon: Icons.logout_rounded,
        label: 'تسجيل الخروج',
        path: '/login',
        currentPath: widget.currentPath,
        collapsed: _sidebarCollapsed,
        onTap: () async {
          await ref.read(authProvider.notifier).logout();
          if (mounted) context.go('/login');
        },
        isDestructive: true,
      ),
    );
  }

  List<_NavItemData> get _navItems => const [
        _NavItemData(icon: Icons.dashboard_rounded, label: 'لوحة المعلومات', path: '/admin'),
        _NavItemData(icon: Icons.people_rounded, label: 'المستخدمون', path: '/admin/users'),
        _NavItemData(icon: Icons.bar_chart_rounded, label: 'الإحصائيات', path: '/admin/analytics'),
        _NavItemData(icon: Icons.group_rounded, label: 'المجموعات', path: '/admin/groups'),
        _NavItemData(icon: Icons.confirmation_number_rounded, label: 'التذاكر', path: '/admin/tickets'),
        _NavItemData(icon: Icons.shield_rounded, label: 'الإشراف', path: '/admin/moderation'),
        _NavItemData(icon: Icons.settings_rounded, label: 'الإعدادات', path: '/admin/settings'),
      ];
}

class _NavItemData {
  final IconData icon;
  final String label;
  final String path;
  const _NavItemData({required this.icon, required this.label, required this.path});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final bool collapsed;
  final VoidCallback onTap;
  final bool isDestructive;

  const _NavItem({required this.icon, required this.label, required this.path, required this.currentPath, required this.collapsed, required this.onTap, this.isDestructive = false});

  bool get isActive => currentPath == path;

  @override
  Widget build(BuildContext context) {
    final fg = isDestructive ? AppColors.error : (isActive ? Colors.white : Colors.white60);
    return Tooltip(
      message: collapsed ? label : '',
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.adminAccent.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive ? Border.all(color: AppColors.adminAccent.withOpacity(0.4)) : null,
          ),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: isActive ? AppColors.adminAccent : fg, size: 20),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: fg, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
