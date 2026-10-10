import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../store.dart';
import '../models.dart';
import '../sync_service.dart';
import 'request_screen.dart';

/// الرئيسية — هيكل فلوسك: شريط علوي، بطاقة متدرجة، دوائر سريعة، شبكة خدمات، بانر إعلانات متحرك
class HomeScreen extends StatefulWidget {
  final LocalStore store;
  final SyncService sync;
  final bool offline;
  final ValueChanged<bool> onToggleOffline;
  final ValueChanged<int> onGoTab;
  const HomeScreen({super.key, required this.store, required this.sync,
      required this.offline, required this.onToggleOffline, required this.onGoTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool hideAmount = true;
  int banner = 0;
  Timer? _timer;

  /// إعلانات افتراضية — تُستبدل بالإعلانات المضافة من الإعدادات
  static const fallbackAds = [
    Ad(id: 'a1', title: 'خصم افتتاحي 30% على كتاب «أساسيات أدوات الذكاء الاصطناعي»', emoji: '🤖📘', badge: 'جديد'),
    Ad(id: 'a2', title: 'أضف منتجك الأول اليوم — يظهر في متجرك فوراً', emoji: '📱✨', badge: '🚀 انطلق'),
    Ad(id: 'a3', title: 'قسم «التخصصات»: مسارات تعلّم لكل كلية — قريباً', emoji: '🎓📚', badge: 'رفيق الطالب'),
  ];

  List<Ad> get _ads {
    final a = widget.store.ads;
    return a.isEmpty ? fallbackAds : a;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final n = _ads.length;
      if (n > 0) setState(() => banner = (banner + 1) % n);
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final st = widget.store;
    return SafeArea(child: AnimatedBuilder(animation: st, builder: (_, __) {
      final ads = _ads;
      final cur = banner % ads.length;
      final ad = ads[cur];
      return ListView(padding: const EdgeInsets.only(bottom: 130), children: [
        // ——— الشريط العلوي ———
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 6), child: Row(children: [
          CircleAvatar(radius: 19, backgroundColor: Dhfa.gold,
              child: const Text('ص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مساء الخير', style: TextStyle(fontSize: 10, color: Dhfa.muted)),
            Text('صادق', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Dhfa.navy)),
          ]),
          const SizedBox(width: 10),
          Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
            child: Row(children: [
              Icon(Icons.search, size: 18, color: Dhfa.muted), SizedBox(width: 6),
              Expanded(child: Text('ابحث عن كتاب أو ملخص…', overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Dhfa.muted))),
            ]))),
          const SizedBox(width: 8),
          _roundIc(Icons.notifications_outlined, badge: true,
              onTap: () => _snack('🔔 طلب جديد — بانتظار تأكيد التحويل')),
          const SizedBox(width: 6),
          _roundIc(widget.offline ? Icons.wifi_off : Icons.wifi,
              onTap: () => widget.onToggleOffline(!widget.offline)),
        ])),
        // ——— البطاقة المتدرجة ———
        Container(margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: Dhfa.heroGradient, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Dhfa.navy.withOpacity(.3), blurRadius: 22, offset: const Offset(0, 10))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('مبيعاتك اليوم', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              GestureDetector(onTap: _refresh, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh, size: 13, color: Dhfa.navy), SizedBox(width: 5),
                  Text('تحديث البيانات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Dhfa.navy)),
                ]))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text(hideAmount ? '*** ريال يمني' : '${st.salesToday} ريال يمني',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              GestureDetector(onTap: () => setState(() => hideAmount = !hideAmount),
                child: Icon(hideAmount ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white70, size: 21)),
            ]),
            const SizedBox(height: 8),
            Text('${st.pendingOrders} طلبات جديدة بانتظار تأكيد التحويل ← اضغط للمراجعة',
                style: const TextStyle(color: Color(0xFFE7CF8E), fontSize: 11.5, fontWeight: FontWeight.w700)),
          ])),
        // ——— الدوائر السريعة ———
        Padding(padding: const EdgeInsets.fromLTRB(10, 12, 10, 2), child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _quick(Icons.menu_book_rounded, 'كتب'),
          _quick(Icons.school_rounded, 'دورات'),
          _quick(Icons.palette_rounded, 'قوالب'),
          _quick(Icons.card_giftcard_rounded, 'مجاني'),
        ])),
        // ——— شبكة الخدمات 3×3 ———
        Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: GridView.count(
          crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.1, children: [
          _svc(Icons.add_circle_outline_rounded, 'إضافة منتج', onTap: () => widget.onGoTab(3)),
          _svc(Icons.format_list_bulleted_rounded, 'منتجاتي', onTap: () => widget.onGoTab(3)),
          _svc(Icons.fact_check_outlined, 'الطلبات', badge: st.pendingOrders, onTap: _ordersSheet),
          _svc(Icons.campaign_outlined, 'الإعلانات', onTap: () => widget.onGoTab(3)),
          _svc(Icons.bar_chart_rounded, 'التقارير', onTap: _showStats),
          _svc(Icons.groups_rounded, 'العملاء', onTap: () => _snack('👥 138 عميلاً مسجلاً')),
          _svc(Icons.sync_rounded, 'المزامنة', onTap: () => widget.onGoTab(2)),
          _svc(Icons.support_agent_rounded, 'الدعم', onTap: () => _snack('🛟 sadeqali2211@gmail.com')),
          _svc(Icons.settings_rounded, 'الإعدادات', onTap: () => widget.onGoTab(3)),
        ])),
        // ——— زر نافذة الطلب ———
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Dhfa.gold, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () => showRequestDialog(context, widget.sync),
            icon: const Icon(Icons.volunteer_activism_rounded),
            label: Text('🙋 اطلب واحنا نلبي — نافذة الطلب', style: TextStyle(fontWeight: FontWeight.w900))))),
        // ——— بانر الإعلانات المتحرك ———
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 6), child: Column(children: [
          AnimatedSwitcher(duration: const Duration(milliseconds: 500),
            child: Container(key: ValueKey(ad.id), width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(gradient: Dhfa.heroGradient, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Dhfa.gold, borderRadius: BorderRadius.circular(999)),
                  child: Text(ad.badge, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900))),
                const SizedBox(width: 10),
                Expanded(child: Text(ad.title,
                    style: const TextStyle(color: Colors.white, fontSize: 12.8, fontWeight: FontWeight.w800, height: 1.5))),
                const SizedBox(width: 8),
                Text(ad.emoji, style: const TextStyle(fontSize: 28)),
              ]))),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < ads.length; i++)
              Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: i == cur ? Dhfa.gold2 : Colors.black26)),
          ]),
        ])),
      ]);
    }));
  }

  Widget _roundIc(IconData ic, {bool badge = false, VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: Stack(children: [
      Container(width: 37, height: 37, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Icon(ic, size: 19, color: Dhfa.navy)),
      if (badge) Positioned(top: 6, left: 7, child: Container(width: 8, height: 8,
          decoration: BoxDecoration(color: Dhfa.gold2, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2)))),
    ]));

  Widget _quick(IconData ic, String label) => GestureDetector(
    onTap: () => widget.onGoTab(1),
    child: Column(children: [
      Container(width: 46, height: 46, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Icon(ic, size: 21, color: Dhfa.navy)),
      const SizedBox(height: 5),
      Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Dhfa.navy)),
    ]));

  Widget _svc(IconData ic, String label, {int badge = 0, String? ribbon, VoidCallback? onTap}) =>
    GestureDetector(onTap: onTap, child: Stack(children: [
      Container(width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ic, size: 22, color: Dhfa.navy),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Dhfa.navy)),
        ])),
      if (badge > 0) Positioned(top: 6, left: 8, child: CircleAvatar(radius: 10, backgroundColor: Dhfa.gold2,
          child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)))),
      if (ribbon != null) Positioned(top: 0, right: 0, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Dhfa.gold2,
            borderRadius: BorderRadius.only(topRight: Radius.circular(18), bottomLeft: Radius.circular(14))),
        child: Text(ribbon, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)))),
    ]));

  /// листة الطلبات (ت opens من زر «الطلبات»)
  void _ordersSheet() {
    final st = widget.store;
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(
        child: Padding(padding: const EdgeInsets.all(18), child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('🧾 طلبات المحفظة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Dhfa.navy)),
            const Spacer(),
            Text('${st.orders.length} طلب', style: TextStyle(fontSize: 11, color: Dhfa.muted, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          if (st.orders.isEmpty)
            Padding(padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('لا توجد طلبات بعد\nتظهر هنا عند إتمام عملية شراء',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Dhfa.muted, fontWeight: FontWeight.w700, height: 1.8)))),
          if (st.orders.isNotEmpty)
            Flexible(child: ListView.builder(shrinkWrap: true, itemCount: st.orders.length,
              itemBuilder: (_, i) {
                final o = st.orders[i];
                return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.productTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Dhfa.navy)),
                      const SizedBox(height: 3),
                      Text('${o.price} ر.ي · مرجع: ${o.ref.isEmpty ? '—' : o.ref} · ${o.time}',
                          style: TextStyle(fontSize: 10.5, color: Dhfa.muted)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFFFF3D6)),
                      child: Text(o.status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Dhfa.gold2))),
                  ]));
              })),
        ])))));
  }

  /// تقرير سريع (dialog)
  void _showStats() {
    final st = widget.store;
    showDialog(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl, child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('📊 تقرير سريع', style: TextStyle(fontWeight: FontWeight.w900, color: Dhfa.navy)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('💰 مبيعاتي اليوم: ${st.salesToday} ر.ي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        SizedBox(height: 6),
        Text('🧾 طلبات اليوم: ${st.pendingOrders}', style: TextStyle(fontSize: 13)),
        SizedBox(height: 6),
        Text('📦 المنتجات: ${st.products.length} (متزامن: ${st.products.where((p) => p.synced).length})', style: TextStyle(fontSize: 13)),
        SizedBox(height: 6),
        Text('📥 منتجات الموقع: ${st.remoteProducts.length}', style: TextStyle(fontSize: 13)),
        SizedBox(height: 6),
        Text('🕒 آخر مزامنة: ${st.lastSync}', style: TextStyle(fontSize: 13)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('فهمت'))],
    )));
  }

  Future<void> _refresh() async {
    if (widget.offline) { _snack('📵 لا يوجد اتصال — المعروض آخر بيانات محفوظة محلياً'); return; }
    _snack('🔄 جارٍ التحديث من الموقع…');
    final msg = await widget.sync.pushPending(widget.store);
    _snack(msg);
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t), behavior: SnackBarBehavior.floating));
}
