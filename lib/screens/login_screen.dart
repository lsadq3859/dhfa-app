import 'package:flutter/material.dart';
import '../theme.dart';
import '../store.dart';

/// شاشة الدخول — بتبويبَي «بوضع الإنترنت / بدون إنترنت» كما في نموذج فلوسك
class LoginScreen extends StatefulWidget {
  final LocalStore store;
  final ValueChanged<bool> onLogin; // true = دخول بوضع محلي
  const LoginScreen({super.key, required this.store, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool offlineMode = false;
  bool hidePw = true;
  final pw = TextEditingController();

  @override
  void dispose() { pw.dispose(); super.dispose(); }

  void _login() {
    if (!widget.store.checkPassword(pw.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ كلمة المرور غير صحيحة — الافتراضية: 123456'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    widget.onLogin(offlineMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 18),
        const Align(alignment: Alignment.centerRight,
          child: Text('مرحباً بعودتك 👋', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Dhfa.navy))),
        const SizedBox(height: 14),
        // شعار دهفة الرسمي (الكتاب وقبعة التخرج)
        Center(child: ClipRRect(borderRadius: BorderRadius.circular(24),
            child: Image.asset('assets/icon_brand.jpg', width: 92, height: 92, fit: BoxFit.cover))),
        const SizedBox(height: 10),
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
          TextField(controller: pw, obscureText: hidePw, decoration: InputDecoration(
            hintText: '123456',
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            suffixIcon: IconButton(icon: Icon(hidePw ? Icons.visibility : Icons.visibility_off, color: Dhfa.muted),
                onPressed: () => setState(() => hidePw = !hidePw)))),
          const SizedBox(height: 4),
          const Text('💡 الافتراضية: 123456 — غيّرها من الإعدادات بعد الدخول',
              style: TextStyle(fontSize: 10, color: Dhfa.muted, fontWeight: FontWeight.w700)),
        ]),
        Align(alignment: Alignment.centerLeft, child: TextButton(
          onPressed: () => showDialog(context: context, builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('🔐 استعادة كلمة المرور', style: TextStyle(fontWeight: FontWeight.w900, color: Dhfa.navy, fontSize: 15)),
              content: const Text('هذا التطبيق لإدارة متجرك — غيّر كلمة المرور من داخل التطبيق:\nالإعدادات → تغيير كلمة المرور',
                  style: TextStyle(fontSize: 12.5, height: 1.9)),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
            ))),
          child: const Text('هل نسيت كلمة المرور؟'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Dhfa.navy, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _login,
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
          child: Text('الإصدار: 1.3', style: TextStyle(fontSize: 11, color: Dhfa.muted, fontWeight: FontWeight.w700))),
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
