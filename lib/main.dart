import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final authService = AuthService();
  await authService.initializeApp();
  deleteOldSongLists();
  runApp(const MyApp());
}

void deleteOldSongLists() async {
  final now = DateTime.now();
  final oneMonthAgo = now.subtract(const Duration(days: 14));
  final querySnapshot = await FirebaseFirestore.instance
      .collection('songLists')
      .where('createdAt', isLessThan: Timestamp.fromDate(oneMonthAgo))
      .get();
  for (var doc in querySnapshot.docs) {
    await FirebaseFirestore.instance
        .collection('songLists')
        .doc(doc.id)
        .delete();
  }
}

// Clase para manejar los colores corporativos
class AppColors {
  static const Color primary =
      Color(0xFF1A7A8B); // Color principal - Azul verdoso
  static const Color secondary =
      Color(0xFFFF6B35); // Color secundario - Naranja
  static const Color background =
      Color(0xFFF8FDFF); // Fondo principal - Azul muy claro
  static const Color cardBackground = Colors.white; // Fondo de tarjetas
  static const Color textPrimary = Color(0xFF2D3B45); // Texto principal
  static const Color textSecondary = Color(0xFF6B7C85); // Texto secundario

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A7A8B),
      Color(0xFF2591A5),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B35),
      Color(0xFFFF8659),
    ],
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Church Management App',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.textPrimary),
            bodyMedium: TextStyle(color: AppColors.textSecondary),
          ),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return ResponsiveWrapper(child: child!);
        },
        routerConfig: AppRouter.router,
      ),
    );
  }
}

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxMobileWidth = 600;
  final double maxWebWidth = 900;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < maxMobileWidth) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.background,
                ],
              ),
            ),
            child: child,
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.background,
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWebWidth,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.08),
                      offset: const Offset(0, -2),
                      blurRadius: 12,
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Decoración de fondo
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.accentGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static double getContentWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return screenWidth;
    } else {
      return 900;
    }
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.symmetric(
        horizontal: 40.0,
        vertical: 32.0,
      );
    }
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;

  const ResponsiveContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getScreenPadding(context),
      width: ResponsiveHelper.getContentWidth(context),
      child: child,
    );
  }
}
