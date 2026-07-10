import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A [NavigatorObserver] that prints the current page name to the
/// debug console every time a route is pushed, popped, or replaced.
///
/// Output example:
///   [PAGE] ▶ /login        → LoginView  (login_view.dart)
///   [PAGE] ▶ /dashboard    → DashboardView  (dashboard_view.dart)
class PageLogger extends NavigatorObserver {
  // Map route path → human-readable file label
  static const Map<String, String> _routeLabels = {
    '/': 'SplashView  (splash_view.dart)',
    '/login': 'LoginView  (login_view.dart)',
    '/dashboard': 'DashboardView  (dashboard_view.dart)',
    '/visitor/detail': 'VisitorDetailView  (visitor_detail_view.dart)',
    '/visitor/list': 'RelatedVisitorsView  (related_visitors_view.dart)',
    '/profile': 'ProfileView  (profile_view.dart)',
    '/configure': 'ConfigureView  (configure_view.dart)',
    '/no-internet': 'NoInternetScreen  (no_internet_screen.dart)',
  };

  void _log(String action, Route? route) {
    if (!kDebugMode) return; // only in debug builds
    final name = route?.settings.name ?? '(unknown)';
    final label = _routeLabels[name] ?? name;
    // ignore: avoid_print
    debugPrint('┌─────────────────────────────────────────');
    // ignore: avoid_print
    debugPrint('│ [PAGE] $action → $label');
    // ignore: avoid_print
    debugPrint('└─────────────────────────────────────────');
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _log('PUSH ', route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _log('BACK ', previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _log('REPLACE', newRoute);
  }
}
