import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../constants/app_colors.dart';
import '../router/app_router.dart';


class AppLoader {
  AppLoader._();

  static bool _isShowing = false;

  static void show() {
    if (_isShowing) return;

    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    _isShowing = true;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Loading",
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: SpinKitRing(
                  color: AppColors.primary,
                  size: 45,
                  lineWidth: 4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide() {
    if (!_isShowing) return;

    final navigator = AppRouter.rootNavigatorKey.currentState;

    if (navigator?.canPop() ?? false) {
      navigator!.pop();
    }

    _isShowing = false;
  }
}