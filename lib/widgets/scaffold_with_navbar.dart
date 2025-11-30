import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.currentUser?.isAdmin ?? false;

    // Calculate current index based on location
    final String location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/admin')) {
      currentIndex = 1;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Actividades',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Salir',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            context.go('/');
          } else if (isAdmin && index == 1) {
            context.go('/admin');
          } else if ((isAdmin && index == 2) || (!isAdmin && index == 1)) {
            // Logout
            authService.logout();
          }
        },
      ),
    );
  }
}
