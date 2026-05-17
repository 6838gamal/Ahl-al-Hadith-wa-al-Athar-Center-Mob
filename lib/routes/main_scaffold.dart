import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_text_styles.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  final String location;

  const MainScaffold({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChat = location.startsWith('/home/chat');
    if (isChat) return Directionality(textDirection: TextDirection.rtl, child: child);

    final user = ref.watch(currentUserProvider);
    final selectedIndex = _selectedIndex(location);

    final navItems = [
      const _NavItem(icon: Icons.home_rounded, label: 'الرئيسية', path: '/home'),
      const _NavItem(icon: Icons.message_rounded, label: 'المحادثات', path: '/home/messages'),
      const _NavItem(icon: Icons.notifications_rounded, label: 'الإشعارات', path: '/home/notifications'),
      const _NavItem(icon: Icons.confirmation_number_rounded, label: 'التذاكر', path: '/home/tickets'),
      const _NavItem(icon: Icons.person_rounded, label: 'حسابي', path: '/home/profile'),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
          onDestinationSelected: (i) => context.go(navItems[i].path),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: navItems.map((item) => NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.icon, color: AppColors.primary),
            label: item.label,
          )).toList(),
        ),
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location == '/home') return 0;
    if (location.startsWith('/home/messages')) return 1;
    if (location.startsWith('/home/notifications')) return 2;
    if (location.startsWith('/home/tickets')) return 3;
    if (location.startsWith('/home/profile')) return 4;
    return 0;
  }
}

class _NavItem {
  final IconData icon;
  final String label, path;
  const _NavItem({required this.icon, required this.label, required this.path});
}
