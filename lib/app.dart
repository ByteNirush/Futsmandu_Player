import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import 'dart:async';

import 'core/design_system/app_spacing.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notifications/local_notification_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/providers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/otp_verification_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/home/home_shell.dart';
import 'features/venues/venue_list_screen.dart';
import 'features/venues/venue_detail_screen.dart';
import 'features/booking/slot_hold_screen.dart';
import 'features/booking/payment_screen.dart';
import 'features/booking/booking_confirm_screen.dart';
import 'features/booking/booking_history_screen.dart';
import 'features/booking/hold_expired_screen.dart';
import 'features/matches/match_detail_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/invite/invite_preview_screen.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/maps/maps_page.dart';
import 'shared/widgets/app_logo.dart';

class FutsmanduApp extends ConsumerStatefulWidget {
  const FutsmanduApp({super.key});

  @override
  ConsumerState<FutsmanduApp> createState() => _FutsmanduAppState();
}

class _FutsmanduAppState extends ConsumerState<FutsmanduApp> {
  final ThemeProvider _themeProvider = ThemeProvider.instance;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription<NotificationResponse>? _notificationTapSubscription;

  @override
  void initState() {
    super.initState();
    _notificationTapSubscription = LocalNotificationService
        .instance.notificationTapStream
        .listen(_handleNotificationResponse);
    _handleLaunchFromNotification();
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleLaunchFromNotification() async {
    final launchDetails =
        await LocalNotificationService.instance.getLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp != true) return;

    final response = launchDetails?.notificationResponse;
    if (response == null) return;
    _handleNotificationResponse(response);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == '/notifications') {
      _navigatorKey.currentState?.pushNamed('/notifications');
      return;
    }
    _navigatorKey.currentState?.pushNamed('/home');
  }

  Widget _themeAware(Widget Function() builder) {
    // Force the active route subtree to rebuild on theme changes.
    // This is necessary because many widgets use `AppColors` (not `Theme.of(context)`)
    // and would otherwise stay visually "stuck" after switching modes.
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (_, __) => builder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    final mediaQuery = MediaQueryData.fromView(View.of(context));
    final adaptiveScale = AppTypographyScale.fromWidth(mediaQuery.size.width);

    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (_, __) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Futsmandu',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeProvider.themeMode,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          if (child == null) {
            return const SizedBox.shrink();
          }
          final mq = MediaQuery.of(context);
          final mergedScale =
              (mq.textScaler.scale(1) * adaptiveScale).clamp(0.85, 1.3);
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(mergedScale)),
            child: child,
          );
        },
        home: authState.when(
          loading: () => const _AuthLoadingScreen(),
          error: (_, __) => _themeAware(() => const LoginScreen()),
          data: (session) {
            if (session != null) {
              return _themeAware(() => const HomeShell());
            }
            return _themeAware(() => const LoginScreen());
          },
        ),
        routes: {
          '/login': (_) => _themeAware(() => const LoginScreen()),
          '/register': (_) => _themeAware(() => const RegisterScreen()),
          '/forgot-password': (_) =>
              _themeAware(() => const ForgotPasswordScreen()),
          '/verify-email': (_) =>
              _themeAware(() => const OtpVerificationScreen()),
          '/otp-verification': (_) =>
              _themeAware(() => const OtpVerificationScreen()),
          '/reset-password': (_) =>
              _themeAware(() => const ResetPasswordScreen()),
          '/home': (_) => _themeAware(() => const HomeShell()),
          '/shell': (_) => _themeAware(() => const HomeShell()),
          '/venues': (_) => _themeAware(() => const VenueListScreen()),
          '/venue-detail': (_) => _themeAware(() => const VenueDetailScreen()),
          '/booking-hold': (_) => _themeAware(() => const SlotHoldScreen()),
          '/payment': (_) => _themeAware(() => const PaymentScreen()),
          '/booking-confirm': (_) =>
              _themeAware(() => const BookingConfirmScreen()),
          '/bookings': (_) => _themeAware(() => const BookingHistoryScreen()),
          '/hold-expired': (_) => _themeAware(() => const HoldExpiredScreen()),
          '/match-detail': (_) => _themeAware(() => const MatchDetailScreen()),
          '/profile': (_) => _themeAware(() => const ProfileScreen()),
          '/notifications': (_) =>
              _themeAware(() => const NotificationsScreen()),
          '/friends': (_) => _themeAware(() => const FriendsScreen()),
          '/invite-preview': (_) =>
              _themeAware(() => const InvitePreviewScreen()),
          '/discovery': (_) => _themeAware(() => const DiscoveryScreen()),
          '/maps': (_) => _themeAware(() => const MapsPage()),
        },
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 72),
            SizedBox(height: AppSpacing.md),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
