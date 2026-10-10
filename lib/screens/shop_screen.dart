import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../store.dart';
import '../models.dart';

/// المتجر — شبكة المنتجات + تصفية حسب القسم + ورقة تفاصيل + شراء بالمحفظة / تحميل مجاني
class ShopScreen extends StatefulWidget {
  final LocalStore store;
  const ShopScreen({super.key, required this.store});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int chip = 0;
  static const chips = ['الكل', '📚 كتب', '🎓 دورات', '🎨 قوالب', '🆓 مجاني'];
  static const sections = ['', 'كتب', 'دورات', 'قوالب', 'مجاني'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: AnimatedBuilder(animation: widget.store, builder: (_, __) {
      final all = widget.store.products;
      final items = chip == 0 ? all : all.where((p) => p.section == sections[chip]).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 4), child: Text('المتجر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Dhfa.navy))),
        SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          for (var i = 0; i < chips.length; i++) _chip(i),
        ])),
        Expanded(child: items.isEmpty
            ? Center(child: Padding(padding: EdgeInsets.all(30), child: Text(
                'لا توجد منتجات في هذا القسم بعد\nأضفها من زر + أو من الإعدادات',
                textAlign: TextAlign.center,
                style: TextStyle(color: Dhfa.muted, fontWeight: FontWeight.w700, height: 1.8))))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .78),
                itemCount: items.length,
                itemBuilder: (_, i) => _card(context, items[i]))),
      ]);
    }));
  }

  Widget _chip(int i) {
    final on = chip == i;
    return GestureDetector(onTap: () => setState(() => chip = i), child: Container(
        margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
            color: on ? Dhfa.navy : Colors.white,
            border: Border.all(color: on ? Dhfa.navy : const Color(0xFFE4E0D4), width: 1.5)),
        child: Text(chips[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
            color: on ? const Color(0xFFE7CF8E) : Dhfa.muted))));
  }

  Widget _card(BuildContext context, Product p) => GestureDetector(
    onTap: () => _details(context, p),
    child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: Container(decoration: BoxDecoration(gradient: Dhfa.heroGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 34))))),
      Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Dhfa.navy, height: 1.5)),
        const SizedBox(height: 5),
        Row(children: [
          Text(p.isFree ? 'مجاني' : '${p.price} ر.ي',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Dhfa.green)),
          const Spacer(),
          if (p.hasFile) Icon(Icons.attach_file_rounded, size: 14, color: Dhfa.gold2),
          if (!p.synced) Text('💾 محلي', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Dhfa.gold2)),
        ]),
      ])),
    ])));

  void _details(BuildContext context, Product p) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Text(p.emoji, style: const TextStyle(fontSize: 60))),
        const SizedBox(height: 10),
        Text(p.title, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Dhfa.navy)),
        const SizedBox(height: 6),
        Text(p.isFree ? 'مجاني — تحميل مباشر' : '${p.price} ريال يمني', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Dhfa.green)),
        const SizedBox(height: 8),
        Text(p.desc.isEmpty
            ? (p.isFree
                ? 'محتوى مجاني — اضغط زر «تحميل مجاني» للحصول على الملف'
                : 'كتاب PDF · عربي · تحميل فوري بعد تأكيد الدفع بالمحفظة (جيب/فلوسك)')
            : p.desc,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Dhfa.muted, height: 1.8)),
        if (p.hasFile) ...[
          const SizedBox(height: 8),
          Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFFFF3D6), borderRadius: BorderRadius.circular(999)),
            child: Text('📎 ${p.fileName.isEmpty ? 'ملف مرفق' : p.fileName}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Dhfa.gold2)))),
        ],
        const SizedBox(height: 14),
        if (p.isFree)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Dhfa.green, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () { Navigator.pop(ctx); _download(p); },
            icon: const Icon(Icons.download_rounded),
            label: const Text('تحميل مجاني', style: TextStyle(fontWeight: FontWeight.w900))),
        if (!p.isFree)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Dhfa.navy, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () { Navigator.pop(ctx); _pay(p); },
            icon: const Icon(Icons.flash_on_rounded),
            label: const Text('شراء بالمحفظة', style: TextStyle(fontWeight: FontWeight.w900))),
        const SizedBox(height: 8),
      ]))));
  }

  /// حوار الدفع — محفظة + الرقم المرجعي للتحويل
  void _pay(Product p) {
    final ref = TextEditingController();
    showDialog(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('الدفع بالمحفظة', style: TextStyle(fontWeight: FontWeight.w900, color: Dhfa.navy, fontSize: 16)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: Dhfa.navy, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('WAL-14-A7F3C21B',
                style: TextStyle(color: Color(0xFFE7CF8E), fontWeight: FontWeight.w900, letterSpacing: 1)))),
          const SizedBox(height: 10),
          const Text('🟡 جيب: 772 092 700', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          Text('🟣 فلوسك: يُضبط من الإعدادات', style: TextStyle(color: Dhfa.muted, fontSize: 12.5)),
          const SizedBox(height: 10),
          Text('المبلغ: ${p.price} ر.ي — حوّل ثم أدخل الرقم المرجعي هنا',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(controller: ref, keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'الرقم المرجعي للتحويل',
              filled: true, fillColor: const Color(0xFFFBFAF6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Dhfa.gold, foregroundColor: Colors.white),
            onPressed: () { Navigator.pop(ctx); _confirm(p, ref.text); },
            child: const Text('✅ تأكيد الدفع', style: TextStyle(fontWeight: FontWeight.w900))),
        ],
      ))).then((_) => ref.dispose());
  }

  /// إتمام الشراء — إنشاء الطلب في المخزن المحلي
  Future<void> _confirm(Product p, String ref) async {
    final order = await widget.store.addOrder(p, ref);
    if (!mounted) return;
    showDialog(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.check_circle_rounded, color: Dhfa.green),
          SizedBox(width: 8),
          Text('تم استلام طلبك ✅', style: TextStyle(fontWeight: FontWeight.w900, color: Dhfa.navy, fontSize: 15)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('المنتج: ${p.title}', style: const TextStyle(fontSize: 12.5, height: 1.8)),
          Text('المبلغ: ${p.price} ر.ي', style: const TextStyle(fontSize: 12.5, height: 1.8)),
          Text('رقم الطلب: ${order.id}',
              style: const TextStyle(fontSize: 12.5, height: 1.8, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('الحالة: بانتظار تأكيد التحويل — ستجده في الرئيسية → الطلبات',
              style: TextStyle(fontSize: 11.5, color: Dhfa.muted, height: 1.8)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
      )));
    _snack('🧾 أُضيف الطلب إلى قائمة الطلبات');
  }

  /// تحميل منتج مجاني — يفتح رابط الملف أو يُبلغ about الملف المحلي
  Future<void> _download(Product p) async {
    if (p.fileUrl.isNotEmpty) {
      final uri = Uri.parse(p.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _snack('⬇️ jarٍ فتح رابط الملف — можноículas от المتصفح');
      } else {
        _snack('⚠️ تعذر فتح الرابط: ${p.fileUrl}');
      }
    } else if (p.filePath.isNotEmpty) {
      _snack('📎 الملف مرفق على الجهاز: ${p.fileName.isEmpty ? p.filePath : p.fileName}');
    } else {
      _snack('⚠️ لا يوجد ملف مرفق — أرفقه من الإعدادات → إضافة منتج');
    }
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t), behavior: SnackBarBehavior.floating));
}
