import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  final String fallbackRoute;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  const AppBackButton({
    super.key,
    this.fallbackRoute = '/home',
    this.foregroundColor,
    this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    final background = backgroundColor ?? Theme.of(context).colorScheme.surface;
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: 'Back',
        mouseCursor: SystemMouseCursors.click,
        onPressed: onPressed ?? () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(fallbackRoute);
          }
        },
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size(44, 44),
          maximumSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
    );
  }
}
