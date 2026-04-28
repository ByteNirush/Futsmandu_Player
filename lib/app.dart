import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import 'dart:async';

import 'core/design_system/app_spacing.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart' show AppTheme;
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
import 'features/booking/book_court_screen.dart';
import 'features/booking/booking_status_screen.dart';
import 'features/booking/payment_screen.dart';
import 'features/booking/payment_history_screen.dart';
import 'features/booking/booking_confirm_screen.dart';
import 'features/booking/booking_history_screen.dart';
// Removed HoldExpiredScreen import
import 'features/matches/match_detail_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/presentation/screens/edit_profile_screen.dart';
import 'features/profile/presentation/screens/public_profile_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/invite/invite_preview_screen.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/maps/maps_page.dart';
import 'package:futsmandu_design_system/components/common/app_logo.dart';

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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQueryData.fromView(View.of(context));
    final adaptiveScale = AppTypographyScale.fromWidth(mediaQuery.size.width);

    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (_, __) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Futsmandu',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
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
        home: const _AuthGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/forgot-password': (_) => const ForgotPasswordScreen(),
          '/verify-email': (_) => const OtpVerificationScreen(),
          '/otp-verification': (_) => const OtpVerificationScreen(),
          '/reset-password': (_) => const ResetPasswordScreen(),
          '/home': (_) => const HomeShell(),
          '/shell': (_) => const HomeShell(),
          '/venues': (_) => const VenueListScreen(),
          '/venue-detail': (_) => const VenueDetailScreen(),
          '/book-court': (_) => const BookCourtScreen(),
          '/booking-status': (_) => const BookingStatusScreen(),
          '/payment': (_) => const PaymentScreen(),
          '/payment-history': (_) => const PaymentHistoryScreen(),
          '/booking-confirm': (_) => const BookingConfirmScreen(),
          '/bookings': (_) => const BookingHistoryScreen(),
          // /hold-expired removed
          '/match-detail': (_) => const MatchDetailScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/profile/edit': (_) => const EditProfileScreen(),
          '/profile/user': (_) => const PublicProfileScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/friends': (_) => const FriendsScreen(),
          '/invite-preview': (_) => const InvitePreviewScreen(),
          '/discovery': (_) => const DiscoveryScreen(),
          '/maps': (_) => const MapsPage(),
        },
      ),
    );
  }
}

/// Separate widget to isolate Riverpod auth state changes from AnimatedBuilder
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);

    return authState.when(
      loading: () => const _AuthLoadingScreen(),
      error: (_, __) => const LoginScreen(),
      data: (session) {
        if (session != null) {
          return const HomeShell();
        }
        return const LoginScreen();
      },
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
