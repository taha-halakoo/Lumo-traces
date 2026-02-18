import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

/// A custom page transition that blurs and scales the previous page
/// while fading in the new page, simulating a "Liquid" dive.
class LiquidPageTransition extends CustomTransitionPage {
  LiquidPageTransition({
    required super.child,
    required LocalKey super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Entrance: Fade + Slide Up
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        );
}
