import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/core/navigation/app_router.dart';
import 'package:Gym/core/theme/app_theme.dart';
import 'package:Gym/features/auth/providers/auth_provider.dart';

class GymCoachingApp extends ConsumerWidget {
  const GymCoachingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authStateProvider);

    if (!authState.isLoading) {
      FlutterNativeSplash.remove();
    }

    return MaterialApp.router(
      title: 'Gym Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
