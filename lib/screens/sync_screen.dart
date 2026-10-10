import 'package:flutter/material.dart';
import '../theme.dart';
import '../store.dart';
import '../sync_service.dart';

/// المزامنة — رفع المحتوى المحلي وسحب الطلبات من الموقع (v1.9)
class SyncScreen extends StatefulWidget {
  final LocalStore store;
  final SyncService sync;
  final bool offline;
  const SyncScreen({super.key, required this.store, required this.sync, required this.offline});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool busy = false;
  final baseCtrl = TextEditingController();
  final keyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    baseCtrl.text = widget.sync.baseUrl;
    keyCtrl.text = widget.sync.apiKey;
  }

  @override
  void dispose() { baseCtrl.dispose(); keyCtrl.dispose(); super.dispose(); }

  String get stateLine => widget.offline
      ? 'بلا إنترنت — الوضع المحلي 💾'
      : (widget.sync.apiKey.isEmpty ? 'متصل — وضع المحاكاة (أدخل المفتاح أسفل)' : 'متصل بالموقع ✓');

  String get subLine => widget.offline
      ? 'تعديلاتك محفوظة على الجهاز وسترتفع عند الاتصال'
      : 'آخر مزامنة: ${widget.store.lastSync} · الوضع: ${widget.sync.mode}';

  @override
  Widget build(BuildContext context) {
    final st = widget.store;
    return SafeArea(child: AnimatedBuilder(animation: st, builder: (_, __) =>
      ListView(padding: const EdgeInsets.all(16), children: [
        const SizedBox(height: 10),
        Center(child: CircleAvatar(radius: 54,
          backgroundColor: widget.offline ? const Color(0xFFFFF3D6) : const Color(0xFFE6F6EC),
          child: busy
              ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3))
              : Icon(Icons.sync_rounded, size: 46, color: widget.offline ? Dhfa.gold2 : Dhfa.green))),
        const SizedBox(height: 12),
        Text(stateLine, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Dhfa.navy)),
        Text(subLine, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Dhfa.muted)),
        const SizedBox(height: 16),
        _box(Column(children: [
          _row('📤 منتجات بانتظار الرفع', '${st.pendingSync}'),
          _row('📥 طلبات معلقة بالموقع', '${st.pendingOrders}'),
          _row('💾 المنتجات على جهازك', '${st.products.length}'),
          _row('📚 منتجات منشورة على الموقع', '${st.remoteProducts.length}', last: true),
        ])),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Dhfa.gold, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: busy ? null : _doSync,
          icon: const Icon(Icons.cloud_upload_rounded),
          label: Text(widget.offline ? '⏳ بانتظار الاتصال…' : '🔄 مزامنة الآن',
              style: const TextStyle(fontWeight: FontWeight.w900))),
        const SizedBox(height: 12),
        // إعدادات الربط مع الموقع
        _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🔗 إعدادات الربط مع موقعك (مرة واحدة)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Dhfa.navy)),
          const SizedBox(height: 8),
          TextField(controller: baseCtrl, textDirection: TextDirection.ltr,
              decoration: _dec('رابط الموقع')),
          const SizedBox(height: 8),
          TextField(controller: keyCtrl, textDirection: TextDirection.ltr, obscureText: true,
              decoration: _dec('مفتاح المزامنة السري')),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Dhfa.navy,
                side: BorderSide(color: Dhfa.navy),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _saveLink,
            icon: const Icon(Icons.save_rounded),
            label: const Text('حفظ الربط', style: TextStyle(fontWeight: FontWeight.w900)))),
          const SizedBox(height: 6),
          Text('المفتاح يُضبط من متغير DHFA_SYNC_API_KEY في Railway وتُدخله هنا مرة واحدة — لا يغادر جهازك إلا مشفراً عبر https.',
              style: TextStyle(fontSize: 10.5, color: Dhfa.muted, height: 1.8)),
        ])),
        const SizedBox(height: 10),
        // ——— منتجات الموقع (المنشورات) ———
        _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📚 منتجات منشورة على الموقع', style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w900, color: Dhfa.navy)),
          SizedBox(height: 8),
          if (st.remoteProducts.isEmpty)
            Text('لم تُسحب بعد — اضغط «مزامنة الآن»', style: TextStyle(fontSize: 11.5, color: Dhfa.muted)),
          for (final p in st.remoteProducts.take(10))
            Container(padding: EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEAE5D6)))),
              child: Row(children: [
                Expanded(child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Dhfa.navy))),
                Text(p.price == 0 ? 'مجاني' : '${p.price} ر.ي',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Dhfa.green)),
              ])),
          if (st.remoteProducts.length > 10)
            Text('+ ${st.remoteProducts.length - 10} منتجاً آخر…',
                style: TextStyle(fontSize: 10.5, color: Dhfa.muted)),
        ])),
        SizedBox(height: 10),
        _box(const Text('🔒 أمان المزامنة: تُرفع المنتجات والإعلانات فقط، وتُسحب الطلبات من الموقع — فلا تتعارض المبيعات الحية أبداً.',
            style: TextStyle(fontSize: 11.5, height: 1.9, color: Color(0xFF6B5320)))),
      ])));
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label,
    labelStyle: TextStyle(fontSize: 11.5, color: Dhfa.muted, fontWeight: FontWeight.w700),
    filled: true, fillColor: const Color(0xFFFBFAF6),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E0D2))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10));

  Widget _box(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 7)]), child: child);

  Widget _row(String a, String b, {bool last = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(
        color: Color(0xFFEAE5D6)))),
    child: Row(children: [Text(a, style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A5468))),
      const Spacer(), Text(b, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Dhfa.navy))]));

  Future<void> _saveLink() async {
    await widget.sync.saveSettings(baseCtrl.text, keyCtrl.text);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.sync.apiKey.isEmpty
          ? '✅ حُفظ — الوضع: محاكاة (أدخل المفتاح للربط الفعلي)'
          : '✅ حُفظ الربط — المزامنة الآن فعلية مع موقعك'),
      behavior: SnackBarBehavior.floating));
  }

  Future<void> _doSync() async {
    if (widget.offline) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('📵 ستتزامن تلقائياً عند عودة الاتصال'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => busy = true);
    final msg = await widget.sync.pushPending(widget.store);
    final pulled = await widget.sync.fetchPendingOrders(widget.store);
    final prods = await widget.sync.fetchProducts(widget.store);
    if (!mounted) return;
    setState(() => busy = false);
    final parts = <String>[msg];
    if (pulled != null) parts.add('الطلبات المعلقة: $pulled');
    if (prods != null) parts.add('المنتجات على الموقع: $prods');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(parts.join(' · ')),
      behavior: SnackBarBehavior.floating));
  }
}
