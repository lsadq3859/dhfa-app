import 'package:flutter/material.dart';
import '../theme.dart';

/// شاشة الدخول — بتبويبَي «بوضع الإنترنت / بدون إنترنت» كما في نموذج فلوسك
class LoginScreen extends StatefulWidget {
  final ValueChanged<bool> onLogin; // true = دخول بوضع محلي
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool offlineMode = false;
  bool hidePw = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 18),
        const Align(alignment: Alignment.centerRight,
          child: Text('مرحباً بعودتك 👋', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Dhfa.navy))),
        const SizedBox(height: 14),
        // شعار نصي مؤقت — تُستبدل بصورة الشعار في أصول التطبيق
        const Icon(Icons.school_rounded, size: 84, color: Dhfa.navy),
        const Text('دهفة', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Dhfa.navy)),
        const Text('رفيق الطالب الجامعي', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Dhfa.gold2)),
        const SizedBox(height: 22),
        // تبويبا الوضع
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]), padding: const EdgeInsets.all(5),
          child: Row(children: [
            _segBtn('الدخول بوضع الإنترنت', Icons.wifi_rounded, !offlineMode, () => setState(() => offlineMode = false)),
            _segBtn('الدخول بدون إنترنت', Icons.wifi_off_rounded, offlineMode, () => setState(() => offlineMode = true)),
          ])),
        if (offlineMode)
          const Padding(padding: EdgeInsets.only(top: 10),
            child: Text('💾 الوضع المحلي: تدخل لمتجرك وتعدّل بلا نت — يتزامن كل شيء عند عودة الاتصال',
                style: TextStyle(fontSize: 11.5, color: Dhfa.gold2, fontWeight: FontWeight.w700))),
        const SizedBox(height: 14),
        _field('أدخل رقم الهاتف أو البريد', const Text('772092700'), TextInputType.phone),
        const SizedBox(height: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('كلمة المرور', style: TextStyle(fontSize: 11.5, color: Dhfa.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(obscureText: hidePw, decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            suffixIcon: IconButton(icon: Icon(hidePw ? Icons.visibility : Icons.visibility_off, color: Dhfa.muted),
                onPressed: () => setState(() => hidePw = !hidePw)))),
        ]),
        Align(alignment: Alignment.centerLeft, child: TextButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('📩 أُرسل رابط الاستعادة إلى بريدك'))),
          child: const Text('هل نسيت كلمة المرور؟'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Dhfa.navy, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: () => widget.onLogin(offlineMode),
          child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Dhfa.navy, side: const BorderSide(color: Dhfa.navy, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✨ إنشاء حساب جديد — في النسخة القادمة'))),
          child: const Text('إنشاء حساب جديد', style: TextStyle(fontWeight: FontWeight.w900))),
        const SizedBox(height: 20),
        const Align(alignment: Alignment.centerLeft,
          child: Text('الإصدار: 1.0', style: TextStyle(fontSize: 11, color: Dhfa.muted, fontWeight: FontWeight.w700))),
      ]))),
    );
  }

  Widget _segBtn(String label, IconData ic, bool on, VoidCallback tap) => Expanded(
    child: GestureDetector(onTap: tap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
            gradient: on ? Dhfa.heroGradient : null),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ic, size: 17, color: on ? Colors.white : Dhfa.muted),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
              color: on ? Colors.white : Dhfa.muted))),
        ]))));

  Widget _field(String label, Text hint, TextInputType type) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11.5, color: Dhfa.muted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      TextField(keyboardType: type, decoration: InputDecoration(hintText: hint.data,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
    ]);
}
