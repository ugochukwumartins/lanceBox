// Displays the supplied LanceBox SVG and the full-screen loading indicator.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../colors.dart';

class Brand extends StatelessWidget {
  final bool wordmark;
  const Brand({super.key, this.wordmark = false});
  // Describe the visible interface using the current values and callbacks.
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // The SVG includes the blue background and the complete logo mark.
      SvgPicture.asset(
        'assets/icons/brand.svg',
        width: 40,
        height: 40,
        semanticsLabel: 'LanceBox logo',
      ),
      if (wordmark)
        const Padding(
          padding: EdgeInsets.only(left: 7),
          child: Text(
            'Lancebox',
            style: TextStyle(
              color: blue,
              fontSize: 26,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    ],
  );
}

/// Full-screen transition matching the supplied loading-state design.
class BrandLoading extends StatelessWidget {
  const BrandLoading({super.key});

  // Describe the visible interface using the current values and callbacks.
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: Center(
      child: Semantics(
        label: 'Loading, please wait',
        child: SizedBox(
          width: 114,
          height: 114,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: CircularProgressIndicator(color: blue, strokeWidth: 1.5),
              ),
              Transform.scale(scale: 1.55, child: const Brand()),
            ],
          ),
        ),
      ),
    ),
  );
}
