import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/technician/activity_list_screen.dart';
import 'screens/technician/activity_form_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'widgets/scaffold_with_navbar.dart';
import 'models/activity_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const AppRouter(),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    final router = GoRouter(
      refreshListenable: authService,
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authService.isAuthenticated;
        final isLoggingIn = state.uri.toString() == '/login';

        if (!isLoggedIn && !isLoggingIn) return '/login';
        if (isLoggedIn && isLoggingIn) return '/';

        // Check admin access
        if (state.uri.toString().startsWith('/admin')) {
          if (!(authService.currentUser?.isAdmin ?? false)) {
            return '/';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return ScaffoldWithNavBar(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const ActivityListScreen(),
            ),
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/activity/new',
          builder: (context, state) => const ActivityFormScreen(),
        ),
        GoRoute(
          path: '/activity/edit',
          builder: (context, state) {
            final activity = state.extra as ActivityModel?;
            return ActivityFormScreen(activity: activity);
          },
        ),
      ],
    );

    if (authService.isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'Tareo',
      theme: AppTheme.theme,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'PE')],
    );
  }
}
