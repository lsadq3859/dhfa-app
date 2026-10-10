import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// هوية دهفة اللونية — قابلة للتخصيص عبر «لوحة الألوان» في الإعدادات
class Dhfa {
  static Color navy = const Color(0xFF0B1D3A);
  static Color navy2 = const Color(0xFF1B3B70);
  static Color gold = const Color(0xFFB8933A);
  static Color gold2 = const Color(0xFF8C6B22);
  static Color bg = const Color(0xFFF4F2EC);
  static const green = Color(0xFF1FA855);
  static const red = Color(0xFFB42318);
  static const muted = Color(0xFF8A93A6);

  static LinearGradient heroGradient = const LinearGradient(
    colors: [Color(0xFF0B1D3A), Color(0xFF1B3B70)],
    begin: Alignment.topRight, end: Alignment.bottomLeft);

  /// متحكّم لوحة الألوان — يُعيد بناء التطبيق عند التغيير
  static final PaletteController palette = PaletteController();

  /// تطبيق لوحة ألوان جديدة
  static void apply(Palette p) {
    navy = p.navy;
    navy2 = p.navy2;
    gold = p.gold;
    gold2 = p.gold2;
    bg = p.bg;
    heroGradient = LinearGradient(
        colors: [p.navy, p.navy2], begin: Alignment.topRight, end: Alignment.bottomLeft);
    palette._set(p);
  }

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: gold),
    scaffoldBackgroundColor: bg,
    fontFamilyFallback: const ['Tahoma', 'Arial'],
    appBarTheme: AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
  );
}

/// لوحة ألوان (nombre + 5 ألوان)
class Palette {
  final String id;
  final String name;
  final Color navy, navy2, gold, gold2, bg;
  const Palette(this.id, this.name, this.navy, this.navy2, this.gold, this.gold2, this.bg);
}

/// مجموعة اللوحات الجاهزة
class Palettes {
  static const def = Palette('default', 'كحلي/ذهبي (افتراضي)',
      Color(0xFF0B1D3A), Color(0xFF1B3B70), Color(0xFFB8933A), Color(0xFF8C6B22), Color(0xFFF4F2EC));
  static const green = Palette('green', 'أخضر/ذهبي',
      Color(0xFF0B3D2E), Color(0xFF14684C), Color(0xFFC9A227), Color(0xFF8C6B22), Color(0xFFF2F7F0));
  static const blue = Palette('blue', 'أزرق/برتقالي',
      Color(0xFF0B2545), Color(0xFF134074), Color(0xFFE8912D), Color(0xFFB26A1B), Color(0xFFEFF4FA));
  static const plum = Palette('plum', 'بنفسجي/ذهبي',
      Color(0xFF2A1240), Color(0xFF4A1E6B), Color(0xFFD4A017), Color(0xFF8C6B22), Color(0xFFF7F2FA));
  static const dark = Palette('dark', 'داكن/ذهبي',
      Color(0xFF101418), Color(0xFF1E2A38), Color(0xFFC9A227), Color(0xFF8C6B22), Color(0xFF14181D));

  static const all = [def, green, blue, plum, dark];

  static Palette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => def);
}

/// متحكّم MVC للوحة الألوان + حفظها
class PaletteController extends ChangeNotifier {
  Palette current = Palettes.def;

  void _set(Palette p) {
    current = p;
    notifyListeners();
  }

  /// استعادة اللوحة المحفوظة (تُستدعى عند إقلاع التطبيق)
  Future<void> restore() async {
    final sp = await SharedPreferences.getInstance();
    final id = sp.getString('dhfa_palette') ?? 'default';
    Dhfa.apply(Palettes.byId(id)); // apply تُحدّث الألوان وتُnotify
  }

  /// حفظ اختيار اللوحة
  Future<void> save(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('dhfa_palette', id);
  }
}

/// أيقونة خطّية ثنائية اللون (لون أساسي + ذهبي) على طريقة فلوسك
class LineIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const LineIcon(this.icon, {super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: Dhfa.navy);
}
