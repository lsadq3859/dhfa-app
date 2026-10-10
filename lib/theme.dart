import 'package:flutter/material.dart';

/// هوية دهفة اللونية المعتمدة (كحلي/ذهبي) — هيكل مستوحى من نموذج فلوسك
class Dhfa {
  static const navy = Color(0xFF0B1D3A);
  static const navy2 = Color(0xFF123064);
  static const gold = Color(0xFFB8933A);
  static const gold2 = Color(0xFF8C6B22);
  static const bg = Color(0xFFF4F2EC);
  static const green = Color(0xFF1FA855);
  static const red = Color(0xFFB42318);
  static const muted = Color(0xFF8A93A6);

  static const heroGradient = LinearGradient(
    colors: [navy, Color(0xFF1B3B70)],
    begin: Alignment.topRight, end: Alignment.bottomLeft);

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: gold),
    scaffoldBackgroundColor: bg,
    fontFamilyFallback: const ['Tahoma', 'Arial'],
    appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
  );
}

/// أيقونة خطّية ثنائية اللون (كحلي + ذهبي) على طريقة فلوسك
class LineIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const LineIcon(this.icon, {super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: Dhfa.navy);
}
