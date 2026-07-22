import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

/// Pops the current route when possible; otherwise navigates to [fallback].
void safePop(
  BuildContext context, {
  String fallback = '/dashboard',
}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(fallback);
}

/// Handles Android system back: pop stack, else go to dashboard from tabs.
void handleRootBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  final location = GoRouterState.of(context).matchedLocation;
  if (location != '/dashboard') {
    context.go('/dashboard');
    return;
  }

  SystemNavigator.pop();
}
