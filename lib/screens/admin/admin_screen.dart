import 'package:flutter/material.dart';
import '../../widgets/user_avatar.dart';
import 'users_screen.dart';
import 'operations_screen.dart';
import 'activity_types_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administración'),
          actions: const [
            Padding(padding: EdgeInsets.only(right: 16.0), child: UserAvatar()),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Usuarios'),
              Tab(text: 'Operaciones'),
              Tab(text: 'Tipos Act.'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [UsersScreen(), OperationsScreen(), ActivityTypesScreen()],
        ),
      ),
    );
  }
}
