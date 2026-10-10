import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../store.dart';
import '../models.dart';

/// المتجر — شبكة موحّدة: منتجات الجهاز + منتجات الموقع (بصورها وتصنيفاتها)
class ShopScreen extends StatefulWidget {
  final LocalStore store;
  const ShopScreen({super.key, required this.store});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String chip = 'الكل'; // 'الكل' | 'مجاني' | اسم تصنيف

  List<Product> get _all => [...widget.store.products, ...widget.store.remoteProducts];

  List<String> get _chips {
    final names = <String>['الكل', 'مجاني'];
    for (final c in widget.store.remoteCategories) {
      final n = (c['name'] ?? '').toString().trim();
      if (n.isNotEmpty && !names.contains(n)) names.add(n);
    }
    for (final p in widget.store.products) {
      if (p.section.isNotEmpty && !names.contains(p.section)) names.add(p.section);
    }
    return names;
  }

  bool _match(Product p) {
    if (chip == 'الكل') return true;
    if (chip == 'مجاني') return p.price == 0;
    final first = chip.split(' ').first;
    final sec = p.section.trim();
    return sec == chip || sec.startsWith(first) || first.startsWith(sec) || sec.contains(first);
  }

  @override
  Widget build(BuildContext context) {
    final items = _all.where(_match).toList();
    return SafeArea(child: AnimatedBuilder(animation: widget.store, builder: (_, __) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Row(children: [
          Text('المتجر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Dhfa.navy)),
          const Spacer(),
          Text('${items.length} منتج · ${widget.store.remoteProducts.length} من الموقع',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Dhfa.muted)),
        ])),
        SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: _chips.map((c) => _Chip(c, c == chip, (v) => setState(() => chip = v))).toList())),
        Expanded(child: items.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🗂️', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text('لا منتجات في هذا القسم', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Dhfa.muted)),
                const SizedBox(height: 4),
                Text('افتح تبويب «المزامنة» ← «اسحب من الموقع»', style: TextStyle(fontSize: 11, color: Dhfa.muted)),
              ]))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .72),
                itemCount: items.length,
                itemBuilder: (_, i) => _card(context, items[i]))),
      ]);
    }));
  }

  Widget _cover(Product p, {double radius = 18, double emojiSize = 34, bool topOnly = true}) {
    final shape = topOnly
        ? BorderRadius.vertical(top: Radius.circular(radius))
        : BorderRadius.circular(radius);
    if (p.imagePath.isNotEmpty && File(p.imagePath).existsSync()) {
      return ClipRRect(borderRadius: shape,
          child: Image.file(File(p.imagePath), width: double.infinity, height: double.infinity, fit: BoxFit.cover));
    }
    if (p.isRemote && p.remoteImage.isNotEmpty) {
      final url = p.remoteImage.startsWith('http') ? p.remoteImage : '${widget.store.siteBase}${p.remoteImage.startsWith('/') ? '' : '/'}${p.remoteImage}';
      return ClipRRect(borderRadius: shape, child: Image.network(url,
          width: double.infinity, height: double.infinity, fit: BoxFit.cover,
          loadingBuilder: (_, child, prog) => prog == null ? child : Container(
              decoration: BoxDecoration(gradient: Dhfa.heroGradient),
              child: const Center(child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70)))),
          errorBuilder: (_, __, ___) => _emojiBox(p, emojiSize, topOnly: topOnly)));
    }
    return _emojiBox(p, emojiSize, topOnly: topOnly);
  }

  Widget _emojiBox(Product p, double size, {bool topOnly = true}) => Container(
      decoration: BoxDecoration(gradient: Dhfa.heroGradient,
          borderRadius: topOnly ? const BorderRadius.vertical(top: Radius.circular(18)) : BorderRadius.circular(18)),
      child: Center(child: Text(p.emoji.isEmpty ? '📦' : p.emoji, style: TextStyle(fontSize: size))));

  Widget _card(BuildContext context, Product p) => GestureDetector(
    onTap: () => _details(context, p),
    child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: _cover(p)),
      Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Dhfa.navy, height: 1.5)),
        const SizedBox(height: 5),
        Row(children: [
          Text(p.price == 0 ? 'مجاني' : '${p.price} ر.ي',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Dhfa.green)),
          const Spacer(),
          if (p.isRemote)
            Text('🌐 الموقع', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Dhfa.navy2))
          else if (!p.synced)
            Text('💾 محلي', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Dhfa.gold2)),
        ]),
      ])),
    ])));

  void _details(BuildContext context, Product p) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: Padding(
        padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: 150, child: _cover(p, radius: 16, emojiSize: 56, topOnly: false)),
        const SizedBox(height: 12),
        Text(p.title, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Dhfa.navy)),
        const SizedBox(height: 6),
        Text(p.price == 0 ? 'مجاني' : '${p.price} ريال يمني', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Dhfa.green)),
        if (p.section.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Dhfa.bg, borderRadius: BorderRadius.circular(999)),
            child: Text(p.section, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Dhfa.navy2)))),
        ],
        if (p.desc.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(p.desc, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Dhfa.muted, height: 1.8)),
        ],
        const SizedBox(height: 8),
        const Text('محتوى رقمي · تسليم فوري بعد تأكيد الدفع بالمحفظة (جيب/فلوسك)',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Dhfa.muted, height: 1.8)),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Dhfa.navy, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: () { Navigator.pop(ctx); _pay(context, p); },
          icon: const Icon(Icons.flash_on_rounded),
          label: const Text('شراء بالمحفظة', style: TextStyle(fontWeight: FontWeight.w900))),
        const SizedBox(height: 8),
      ])))));
  }

  void _pay(BuildContext context, Product p) {
    showDialog(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('الدفع بالمحفظة', style: TextStyle(fontWeight: FontWeight.w900, color: Dhfa.navy, fontSize: 16)),
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
  final String t; final bool on; final ValueChanged<String> pick;
  const _Chip(this.t, this.on, this.pick);
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: () => pick(t),
    child: Container(
      margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 15),
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
          color: on ? Dhfa.navy : Colors.white,
          border: Border.all(color: on ? Dhfa.navy : const Color(0xFFE4E0D4), width: 1.5)),
      child: Text(t == 'مجاني' ? '🆓 مجاني' : (t == 'الكل' ? 'الكل' : '🏷️ $t'),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
              color: on ? const Color(0xFFE7CF8E) : Dhfa.muted))));
}
