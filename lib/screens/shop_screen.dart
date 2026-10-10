import 'package:flutter/material.dart';
import '../theme.dart';
import '../store.dart';
import '../models.dart';

/// المتجر — شبكة المنتجات + ورقة تفاصيل + شراء بالمحفظة
class ShopScreen extends StatelessWidget {
  final LocalStore store;
  const ShopScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: AnimatedBuilder(animation: store, builder: (_, __) {
      final items = store.products;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 4), child: Text('المتجر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Dhfa.navy))),
        SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16), children: const [
          _Chip('الكل', true), _Chip('📚 كتب', false), _Chip('🎓 دورات', false),
          _Chip('🎨 قوالب', false), _Chip('🆓 مجاني', false),
        ])),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .78),
          itemCount: items.length,
          itemBuilder: (_, i) => _card(context, items[i]))),
      ]);
    }));
  }

  Widget _card(BuildContext context, Product p) => GestureDetector(
    onTap: () => _details(context, p),
    child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: Container(decoration: const BoxDecoration(gradient: Dhfa.heroGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 34))))),
      Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Dhfa.navy, height: 1.5)),
        const SizedBox(height: 5),
        Row(children: [
          Text(p.price == 0 ? 'مجاني' : '${p.price} ر.ي',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Dhfa.green)),
          const Spacer(),
          if (!p.synced) const Text('💾 محلي', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Dhfa.gold2)),
        ]),
      ])),
    ])));

  void _details(BuildContext context, Product p) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: Padding(
        padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Text(p.emoji, style: const TextStyle(fontSize: 60))),
        const SizedBox(height: 10),
        Text(p.title, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Dhfa.navy)),
        const SizedBox(height: 6),
        Text(p.price == 0 ? 'مجاني' : '${p.price} ريال يمني', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Dhfa.green)),
        const SizedBox(height: 8),
        const Text('كتاب PDF · عربي · تحميل فوري بعد تأكيد الدفع بالمحفظة (جيب/فلوسك)',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Dhfa.muted, height: 1.8)),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Dhfa.navy, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: () { Navigator.pop(ctx); _pay(context, p); },
          icon: const Icon(Icons.flash_on_rounded),
          label: const Text('شراء بالمحفظة', style: TextStyle(fontWeight: FontWeight.w900))),
        const SizedBox(height: 8),
      ]))));
  }

  void _pay(BuildContext context, Product p) {
    showDialog(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('الدفع بالمحفظة', style: TextStyle(fontWeight: FontWeight.w900, color: Dhfa.navy, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: Dhfa.navy, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('WAL-14-A7F3C21B',
                style: TextStyle(color: Color(0xFFE7CF8E), fontWeight: FontWeight.w900, letterSpacing: 1)))),
          const SizedBox(height: 10),
          const Text('🟡 جيب: 772 092 700', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('🟣 فلوسك: يُضبط من الإعدادات', style: TextStyle(color: Dhfa.muted, fontSize: 12.5)),
          const SizedBox(height: 10),
          Text('حوّل ${p.price} ر.ي وأرسل الإشعار بالبريد مع الرقم المرجعي — يُسلَّم المنتج فور تأكيد الإدارة.',
              style: const TextStyle(fontSize: 12, height: 1.9)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('فهمت'))],
      )));
  }
}

class _Chip extends StatelessWidget {
  final String t; final bool on;
  const _Chip(this.t, this.on);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 15),
    alignment: Alignment.center,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
        color: on ? Dhfa.navy : Colors.white,
        border: Border.all(color: on ? Dhfa.navy : const Color(0xFFE4E0D4), width: 1.5)),
    child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
        color: on ? const Color(0xFFE7CF8E) : Dhfa.muted)));
}
