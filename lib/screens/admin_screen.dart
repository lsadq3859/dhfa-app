import 'package:flutter/material.dart';
import '../theme.dart';
import '../store.dart';

/// الإدارة — إضافة منتج محلياً + قائمة منتجاتي وحالات المزامنة
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
  String section = 'كتب';

  @override
  void dispose() { title.dispose(); price.dispose(); emoji.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final st = widget.store;
    final body = ListView(padding: EdgeInsets.zero, children: [
      Container(margin: const EdgeInsets.fromLTRB(16, 14, 16, 0), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: Dhfa.heroGradient, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🛠️ لوحة متجري', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          AnimatedBuilder(animation: st, builder: (_, __) => Row(children: [
            _stat('${st.products.length}', 'منتجات'),
            _stat('${st.pendingSync}', 'بانتظار المزامنة'),
            _stat('${st.pendingOrders}', 'طلبات اليوم'),
          ])),
        ])),
      Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('➕ إضافة منتج جديد', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Dhfa.navy)),
          const SizedBox(height: 10),
          _in(title, 'اسم المنتج'),
          const SizedBox(height: 8),
          _in(price, 'السعر (ر.ي)', TextInputType.number),
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
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Dhfa.gold, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('حفظ محلياً', style: TextStyle(fontWeight: FontWeight.w900)))),
        ])),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('منتجاتي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Dhfa.navy))),
      const SizedBox(height: 6),
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Dhfa.navy)),
                Text(p.price == 0 ? 'مجاني' : '${p.price} ر.ي · ${p.section}',
                    style: const TextStyle(fontSize: 10, color: Dhfa.muted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
                    color: p.synced ? const Color(0xFFE6F6EC) : const Color(0xFFFFF3D6)),
                child: Text(p.synced ? '✓ متزامن' : '⏳ بالانتظار',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900,
                        color: p.synced ? Dhfa.green : Dhfa.gold2))),
            ])),
      ])),
      const SizedBox(height: 20),
    ]);

    final wrapped = SafeArea(child: body);
    if (widget.autofocusForm) {
      return Scaffold(appBar: AppBar(title: const Text('إضافة منتج سريعة')), body: wrapped);
    }
    return wrapped;
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label,
    labelStyle: const TextStyle(fontSize: 11.5, color: Dhfa.muted, fontWeight: FontWeight.w700),
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

  Widget _in(TextEditingController c, String label, [TextInputType? t]) =>
      TextField(controller: c, keyboardType: t, decoration: _dec(label));

  Future<void> _save() async {
    final t = title.text.trim();
    final p = int.tryParse(price.text.trim()) ?? 0;
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسم المنتج أولاً')));
      return;
    }
    await widget.store.addProduct(t, p, section, emoji.text.trim().isEmpty ? '📦' : emoji.text.trim());
    title.clear(); price.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.offline ? '💾 حُفظ محلياً — سيتزامن عند الاتصال' : '✅ حُفظ — ارفعه من شاشة المزامنة'),
      behavior: SnackBarBehavior.floating));
  }
}
