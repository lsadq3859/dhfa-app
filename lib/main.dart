import 'package:flutter/material.dart';
import 'theme.dart';
import 'store.dart';
import 'sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/sync_screen.dart';

void main() => runApp(const DhfaApp());

class DhfaApp extends StatelessWidget {
  const DhfaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'دهفة — رفيق الطالب الجامعي',
    debugShowCheckedModeBanner: false,
    theme: Dhfa.theme(),
    locale: const Locale('ar'),
    builder: (ctx, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const LoginGate(),
  );
}

/// بوابة الدخول ثم الغلاف الرئيسي
class LoginGate extends StatefulWidget {
  const LoginGate({super.key});
  @override
  State<LoginGate> createState() => _LoginGateState();
}

class _LoginGateState extends State<LoginGate> {
  final store = LocalStore();
  final sync = SyncService();
  bool loggedIn = false;
  bool offline = false;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    store.load();
    sync.restore();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!store.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!loggedIn) {
      return LoginScreen(store: store, onLogin: (off) => setState(() { loggedIn = true; offline = off; }));
    }
    return MainShell(store: store, sync: sync, offline: offline,
        onToggleOffline: (v) => setState(() => offline = v));
  }
}

/// الغلاف: شاشات + شريط سفلي بزر مركزي (على طريقة فلوسك)
class MainShell extends StatefulWidget {
  final LocalStore store;
  final SyncService sync;
  final bool offline;
  final ValueChanged<bool> onToggleOffline;
  const MainShell({super.key, required this.store, required this.sync,
      required this.offline, required this.onToggleOffline});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(store: widget.store, sync: widget.sync, offline: widget.offline,
          onToggleOffline: widget.onToggleOffline, onGoTab: (i) => setState(() => index = i)),
      ShopScreen(store: widget.store),
      SyncScreen(store: widget.store, sync: widget.sync, offline: widget.offline),
      AdminScreen(store: widget.store, offline: widget.offline, autofocusForm: false),
    ];
    return Scaffold(
      body: Column(children: [
        if (widget.offline)
          Container(width: double.infinity, color: Dhfa.gold2, padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Text('📵 وضع عدم الاتصال — تعديلاتك محفوظة محلياً وستتزامن لاحقاً',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700))),
        Expanded(child: IndexedStack(index: index, children: pages)),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Dhfa.gold,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AdminScreen(store: widget.store, offline: widget.offline, autofocusForm: true))),
        child: const Icon(Icons.add, color: Colors.white, size: 26)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), notchMargin: 8, color: Colors.white,
        child: SizedBox(height: 60, child: Row(children: [
          _tab(0, Icons.home_rounded, 'الرئيسية'),
          _tab(1, Icons.storefront_rounded, 'المتجر'),
          const SizedBox(width: 56),
          _tab(2, Icons.bar_chart_rounded, 'التقارير'),
          _tab(3, Icons.settings_rounded, 'الإعدادات'),
        ])),
      ),
    );
  }

  Widget _tab(int i, IconData ic, String label) {
    final on = index == i;
    return Expanded(child: InkWell(onTap: () => setState(() => index = i),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(ic, color: on ? Dhfa.gold2 : Dhfa.muted, size: 23),
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800,
            color: on ? Dhfa.navy : Dhfa.muted)),
      ])));
  }
}
