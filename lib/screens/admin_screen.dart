import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../store.dart';

/// الإدارة (الإعدادات) — إضافة منتج + إعلانات + تغيير كلمة المرور + قائمة منتجاتي
class AdminScreen extends StatefulWidget {
  final LocalStore store;
  final bool offline;
  final bool autofocusForm;
  const AdminScreen({super.key, required this.store, required this.offline, this.autofocusForm = false});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final title = TextEditingController();
  final price = TextEditingController();
  final emoji = TextEditingController(text: '📘');
  final desc = TextEditingController();
  final fileUrl = TextEditingController();
  String section = 'كتب';
  String? fileName;
  String? filePath;
  bool picking = false;

  final oldPw = TextEditingController();
  final newPw = TextEditingController();
  final newPw2 = TextEditingController();

  final adTitle = TextEditingController();
  final adBadge = TextEditingController(text: 'جديد');
  final adEmoji = TextEditingController(text: '📣');

  @override
  void dispose() {
    for (final c in [title, price, emoji, desc, fileUrl,
        oldPw, newPw, newPw2, adTitle, adBadge, adEmoji]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.store;
    final body = ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      // ——— إحصائيات ———
      Container(margin: const EdgeInsets.fromLTRB(16, 14, 16, 0), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: Dhfa.heroGradient, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🛠️ لوحة متجري', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          AnimatedBuilder(animation: st, builder: (_, __) => Row(children: [
            _stat('${st.products.length}', 'منتجات'),
            _stat('${st.pendingSync}', 'بانتظار المزامنة'),
            _stat('${st.orders.length}', 'الطلبات'),
          ])),
        ])),
      // ——— إضافة منتج ———
      _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('➕ إضافة منتج جديد', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Dhfa.navy)),
        const SizedBox(height: 10),
        _in(title, 'اسم المنتج'),
        const SizedBox(height: 8),
        _in(price, 'السعر (ر.ي) — اترك 0 للمجاني', t: TextInputType.number),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: section,
            decoration: _dec('القسم'),
            items: const [
              DropdownMenuItem(value: 'كتب', child: Text('📚 كتب')),
              DropdownMenuItem(value: 'دورات', child: Text('🎓 دورات')),
              DropdownMenuItem(value: 'قوالب', child: Text('🎨 قوالب')),
              DropdownMenuItem(value: 'مجاني', child: Text('🆓 مجاني')),
            ], onChanged: (v) => setState(() => section = v ?? 'كتب'))),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: _in(emoji, 'أيقونة')),
        ]),
        const SizedBox(height: 8),
        _in(desc, 'وصف مختصر (اختياري)'),
        const SizedBox(height: 8),
        _in(fileUrl, 'رابط الملف (PDF) — رابط مباشر', t: TextInputType.url, ltr: true),
        const SizedBox(height: 8),
        _attachRow(),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Dhfa.gold, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('حفظ المنتج', style: TextStyle(fontWeight: FontWeight.w900)))),
      ])),
      // ——— الإعلانات ———
      AnimatedBuilder(animation: st, builder: (_, __) => _box(Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('📣 الإعلانات', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Dhfa.navy)),
          const Spacer(),
          Text('${st.ads.length} إعلان · يظهر في الرئيسية',
              style: TextStyle(fontSize: 10, color: Dhfa.muted, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        _in(adTitle, 'نص الإعلان'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _in(adBadge, 'الشارة')),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: _in(adEmoji, 'أيقونة')),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Dhfa.navy,
              side: BorderSide(color: Dhfa.navy),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _saveAd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('نشر الإعلان', style: TextStyle(fontWeight: FontWeight.w900)))),
        const SizedBox(height: 10),
        for (final a in st.ads)
          Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xFFFBFAF6), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAE5D6))),
            child: Row(children: [
              Text(a.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Dhfa.navy))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Dhfa.gold, borderRadius: BorderRadius.circular(999)),
                child: Text(a.badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
              IconButton(icon: Icon(Icons.delete_outline_rounded, color: Dhfa.red, size: 19),
                  onPressed: () => widget.store.removeAd(a.id)),
            ])),
      ]))),
      // ——— كلمة المرور ———
      _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🔐 تغيير كلمة المرور', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Dhfa.navy)),
        const SizedBox(height: 8),
        _in(oldPw, 'كلمة المرور الحالية', t: TextInputType.visiblePassword, obscure: true),
        const SizedBox(height: 8),
        _in(newPw, 'كلمة المرور الجديدة', t: TextInputType.visiblePassword, obscure: true),
        const SizedBox(height: 8),
        _in(newPw2, 'تأكيد كلمة المرور الجديدة', t: TextInputType.visiblePassword, obscure: true),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Dhfa.navy, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _savePw,
          icon: const Icon(Icons.lock_reset_rounded),
          label: const Text('تحديث كلمة المرور', style: TextStyle(fontWeight: FontWeight.w900)))),
        const SizedBox(height: 6),
        Text('تُحفظ مشفرة (SHA-256) على جهازك فقط — لا تُرسل إلى أي مكان',
            style: TextStyle(fontSize: 10, color: Dhfa.muted)),
      ])),
      // ——— منتجاتي ———
      Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: Text('منتجاتي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Dhfa.navy))),
      AnimatedBuilder(animation: st, builder: (_, __) => Column(children: [
        for (final p in st.products)
          Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(gradient: Dhfa.heroGradient,
                  borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 17)))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Dhfa.navy)),
                Text(p.isFree
                    ? 'مجاني · ${p.section}${p.hasFile ? ' · 📎 ملف' : ''}'
                    : '${p.price} ر.ي · ${p.section}${p.hasFile ? ' · 📎 ملف' : ''}',
                    style: TextStyle(fontSize: 10, color: Dhfa.muted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
                    color: p.synced ? const Color(0xFFE6F6EC) : const Color(0xFFFFF3D6)),
                child: Text(p.synced ? '✓ متزامن' : '⏳ بالانتظار',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900,
                        color: p.synced ? Dhfa.green : Dhfa.gold2))),
            ])),
      ])),
      // ——— لوحة الألوان ———
      ListenableBuilder(listenable: Dhfa.palette, builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🎨 لوحة الألوان', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Dhfa.navy)),
          SizedBox(height: 4),
          Text('اختر لون التطبيق — يتغير فوراً', style: TextStyle(fontSize: 11, color: Dhfa.muted)),
          SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final p in Palettes.all) _paletteDot(p),
          ]),
        ]))),

    ]);

    final wrapped = SafeArea(child: body);
    if (widget.autofocusForm) {
      return Scaffold(appBar: AppBar(title: const Text('إضافة منتج سريعة')), body: wrapped);
    }
    return wrapped;
  }

  Widget _box(Widget child) => Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: child);

  Widget _attachRow() => GestureDetector(onTap: picking ? null : _pickFile,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: const Color(0xFFFBFAF6), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E0D2), width: 1.5)),
      child: Row(children: [
        Icon(picking ? Icons.hourglass_top_rounded : Icons.attach_file_rounded, color: Dhfa.navy, size: 19),
        const SizedBox(width: 8),
        Expanded(child: Text(
          picking ? 'جارٍ الاختيار…' : (fileName == null ? '📎 إرفاق ملف من الجهاز (PDF)' : '📄 $fileName'),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
              color: fileName == null ? Dhfa.muted : Dhfa.navy))),
        if (fileName != null)
          GestureDetector(onTap: () => setState(() { fileName = null; filePath = null; }),
            child: Icon(Icons.close_rounded, size: 17, color: Dhfa.red)),
      ])));

  Future<void> _pickFile() async {
    setState(() => picking = true);
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'epub', 'zip', 'doc', 'docx']);
      if (r != null && r.files.isNotEmpty) {
        setState(() { fileName = r.files.single.name; filePath = r.files.single.path; });
      }
    } catch (_) {
      if (mounted) _snack('⚠️ تعذر اختيار الملف');
    }
    if (mounted) setState(() => picking = false);
  }

  Widget _paletteDot(Palette p) {
    final on = Dhfa.palette.current.id == p.id;
    return GestureDetector(onTap: () async {
      Dhfa.apply(p);
      await Dhfa.palette.save(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎨 تم تطبيق لوحة: ${p.name}'),
          behavior: SnackBarBehavior.floating));
    },
    child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: on ? Dhfa.navy : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? Dhfa.navy : Color(0xFFE4E0D4), width: 1.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: p.navy, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1))),
        SizedBox(width: 4),
        Container(width: 10, height: 10, decoration: BoxDecoration(color: p.gold, shape: BoxShape.circle)),
        SizedBox(width: 8),
        Text(p.name, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800,
            color: on ? Color(0xFFE7CF8E) : Dhfa.navy)),
        if (on) ...[SizedBox(width: 6), Icon(Icons.check_circle, size: 15, color: Color(0xFFE7CF8E))],
      ])));
  }

  Future<void> _save() async {
    final t = title.text.trim();
    final p = int.tryParse(price.text.trim()) ?? 0;
    if (t.isEmpty) { _snack('✍️ اكتب اسم المنتج أولاً'); return; }
    final hadFile = fileName != null;
    await widget.store.addProduct(title: t, price: p, section: section,
        emoji: emoji.text.trim().isEmpty ? '📦' : emoji.text.trim(),
        desc: desc.text.trim(), fileUrl: fileUrl.text.trim(),
        filePath: filePath ?? '', fileName: fileName ?? '');
    title.clear(); price.clear(); desc.clear(); fileUrl.clear();
    setState(() { fileName = null; filePath = null; });
    if (!mounted) return;
    _snack(widget.offline
        ? '💾 حُفظ محلياً${hadFile ? ' مع الملف 📎' : ''} — سيتزامن عند الاتصال'
        : '✅ حُفظ${hadFile ? ' مع الملف 📎' : ''} — ارفعه من شاشة المزامنة');
  }

  Future<void> _saveAd() async {
    final t = adTitle.text.trim();
    if (t.isEmpty) { _snack('✍️ اكتب نص الإعلان أولاً'); return; }
    await widget.store.addAd(t,
        adEmoji.text.trim().isEmpty ? '📣' : adEmoji.text.trim(),
        adBadge.text.trim().isEmpty ? 'جديد' : adBadge.text.trim());
    adTitle.clear();
    if (!mounted) return;
    _snack('📣 نُشر الإعلان — سيظهر في بانر الرئيسية');
  }

  Future<void> _savePw() async {
    if (newPw.text != newPw2.text) { _snack('❌ تأكيد كلمة المرور غير مطابق'); return; }
    final err = await widget.store.changePassword(oldPw.text, newPw.text);
    if (err != null) { _snack('❌ $err'); return; }
    oldPw.clear(); newPw.clear(); newPw2.clear();
    if (!mounted) return;
    _snack('🔐 تم تغيير كلمة المرور — مطلوبة من تسجيل الدخول التالي');
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label,
    labelStyle: TextStyle(fontSize: 11.5, color: Dhfa.muted, fontWeight: FontWeight.w700),
    filled: true, fillColor: const Color(0xFFFBFAF6),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E0D2))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10));

  Widget _stat(String value, String label) => Expanded(child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.1),
        borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
    child: Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
    ])));

  Widget _in(TextEditingController c, String label, {TextInputType? t, bool obscure = false, bool ltr = false}) =>
      TextField(controller: c, keyboardType: t, obscureText: obscure,
          textDirection: ltr ? TextDirection.ltr : null, decoration: _dec(label));

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t), behavior: SnackBarBehavior.floating));
}
