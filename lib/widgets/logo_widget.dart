import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ElegoPrimeLogo extends StatelessWidget {
  final double elegoFontSize;
  final double primeFontSize;
  final bool showSvgLogo;
  final MainAxisAlignment alignment;

  const ElegoPrimeLogo({
    super.key,
    this.elegoFontSize = 20,
    this.primeFontSize = 16,
    this.showSvgLogo = false,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (showSvgLogo) {
      // Combined logo with text on right
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignment,
        children: [
          // SVG Logo
          _buildSvgLogo(),
          const SizedBox(width: 8),
          // Text logo
          _buildTextLogo(),
        ],
      );
    } else {
      // Text only logo
      return _buildTextLogo();
    }
  }

  Widget _buildSvgLogo() {
    return SizedBox(
      width: 36,
      height: 36,
      child: SvgPicture.asset(
        'assets/images/logoelego.svg',
        colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
        fit: BoxFit.contain,
        // Make the SVG content smaller within its container
        width: 30,
        height: 30,
      ),
    );
  }

  Widget _buildTextLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ELEGO',
          style: TextStyle(
            fontSize: elegoFontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A365D), // Dark blue
            height: 0.9,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'PRIME',
          style: TextStyle(
            fontSize: primeFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
