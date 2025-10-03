import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/login/login_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/production/production_screen.dart';
import '../screens/worship/worship_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/production',
        builder: (context, state) => const ProductionScreen(),
      ),
      GoRoute(
        path: '/worship',
        builder: (context, state) => const WorshipScreen(),
      ),
    ],
  );
}