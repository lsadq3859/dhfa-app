import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// المخزن المحلي: منتجاتك + طلباتك + إعلاناتك + كلمة المرور — يعمل بدون إنترنت بالكامل
class LocalStore extends ChangeNotifier {
  static const _kProducts = 'dhfa_products';
  static const _kLastSync = 'dhfa_last_sync';
  static const _kOrders = 'dhfa_pending_orders';
  static const _kOrdersList = 'dhfa_orders_list';
  static const _kSales = 'dhfa_sales_today';
  static const _kAds = 'dhfa_ads';
  static const _kPw = 'dhfa_pw_hash';
  static const _kRemote = 'dhfa_remote_products';

  List<Product> products = [];
  List<Product> remoteProducts = []; // منتجات منشورة على الموقع (تُجلب بالمزامنة)
  List<Order> orders = [];
  List<Ad> ads = [];
  int pendingOrders = 4; // تجريبي حتى ربط واجهة الموقع v1.9
  int salesToday = 18500;
  String lastSync = 'لم تتم بعد';
  bool ready = false;

  String _pwHash = _hash('123456'); // كلمة المرور الافتراضية — غيّرها من الإعدادات

  int get pendingSync => products.where((p) => !p.synced).length;

  static String _hash(String s) => sha256.convert(utf8.encode(s)).toString();

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProducts);
    if (raw != null && raw.isNotEmpty) {
      products = Product.decodeList(raw);
    } else {
      products = _seed();
      await _save(sp);
    }
    final rawAds = sp.getString(_kAds);
    if (rawAds != null && rawAds.isNotEmpty) {
      ads = Ad.decodeList(rawAds);
    } else {
      ads = _seedAds();
      await _saveAds(sp);
    }
    final rawOrders = sp.getString(_kOrdersList);
    if (rawOrders != null && rawOrders.isNotEmpty) {
      orders = Order.decodeList(rawOrders);
    }
    final rawRemote = sp.getString(_kRemote);
    if (rawRemote != null && rawRemote.isNotEmpty) {
      remoteProducts = Product.decodeList(rawRemote);
    }
    lastSync = sp.getString(_kLastSync) ?? lastSync;
    pendingOrders = sp.getInt(_kOrders) ?? pendingOrders;
    salesToday = sp.getInt(_kSales) ?? salesToday;
    _pwHash = sp.getString(_kPw) ?? _pwHash;
    ready = true;
    notifyListeners();
  }

  List<Product> _seed() => [
    Product(id: 'p1', title: 'أساسيات التعامل مع أدوات الذكاء الاصطناعي', price: 4500,
        section: 'كتب', emoji: '🤖', desc: 'مقدمة عملية لأدوات الذكاء الاصطناعي مع أمثلة تطبيقية'),
    Product(id: 'p2', title: 'التسويق الرقمي للمبتدئين', price: 3000,
        section: 'كتب', emoji: '📈', desc: 'كل ما يحتاجه المبتدئ في التسويق الرقمي'),
    Product(id: 'p3', title: 'قوالب تصاميم سوشيال ميديا', price: 2000,
        section: 'قوالب', emoji: '🎨', desc: 'قوالب جاهزة لمنشورات السوشيال ميديا'),
    Product(id: 'p4', title: 'دورة إدارة المشاريع الصغيرة', price: 0,
        section: 'مجاني', emoji: '💼', desc: 'محتوى مجاني متكامل — حمله مباشرة',
        fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        fileName: 'dummy.pdf'),
  ];

  List<Ad> _seedAds() => const [
    Ad(id: 'a1', title: 'خصم افتتاحي 30% على كتاب «أساسيات أدوات الذكاء الاصطناعي»', emoji: '🤖📘', badge: 'جديد'),
    Ad(id: 'a2', title: 'أضف منتجك الأول اليوم — يظهر في متجرك فوراً', emoji: '📱✨', badge: '🚀 انطلق'),
    Ad(id: 'a3', title: 'قسم «التخصصات»: مسارات تعلّم لكل كلية — قريباً', emoji: '🎓📚', badge: 'رفيق الطالب'),
  ];

  Future<void> _save([SharedPreferences? sp]) async {
    sp ??= await SharedPreferences.getInstance();
    await sp.setString(_kProducts, Product.encodeList(products));
  }

  Future<void> _saveOrders([SharedPreferences? sp]) async {
    sp ??= await SharedPreferences.getInstance();
    await sp.setString(_kOrdersList, Order.encodeList(orders));
  }

  Future<void> _saveAds([SharedPreferences? sp]) async {
    sp ??= await SharedPreferences.getInstance();
    await sp.setString(_kAds, Ad.encodeList(ads));
  }

  /// إضافة منتج محلياً (يعمل بلا إنترنت — يرتفع عند المزامنة)
  Future<void> addProduct({required String title, required int price, required String section,
      required String emoji, String desc = '', String fileUrl = '',
      String filePath = '', String fileName = ''}) async {
    products.insert(0, Product(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      title: title, price: price, section: section, emoji: emoji,
      desc: desc, fileUrl: fileUrl, filePath: filePath, fileName: fileName, synced: false));
    await _save();
    notifyListeners();
  }

  /// تسجيل طلب شراء جديد (عند تأكيد الدفع بالمحفظة) — يُرجع الطلب المُنشأ
  Future<Order> addOrder(Product p, String ref) async {
    final n = DateTime.now();
    final order = Order(
      id: 'ORD-${n.millisecondsSinceEpoch}',
      productTitle: p.title, price: p.price, ref: ref.trim(),
      time: '${n.day}/${n.month} ${n.hour}:${n.minute.toString().padLeft(2, '0')}');
    orders.insert(0, order);
    pendingOrders += 1;
    salesToday += p.price;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kOrders, pendingOrders);
    await sp.setInt(_kSales, salesToday);
    await _saveOrders(sp);
    notifyListeners();
    return order;
  }

  /// إضافة إعلان — يظهر في البانر المتحرك بالرئيسية
  Future<void> addAd(String title, String emoji, String badge) async {
    ads.insert(0, Ad(id: 'ad${DateTime.now().millisecondsSinceEpoch}',
        title: title, emoji: emoji, badge: badge));
    await _saveAds();
    notifyListeners();
  }

  Future<void> removeAd(String id) async {
    ads.removeWhere((a) => a.id == id);
    await _saveAds();
    notifyListeners();
  }

  bool checkPassword(String pw) => _hash(pw) == _pwHash;

  /// تغيير كلمة المرور — يُرجع null عند النجاح أو رسالة الخطأ
  Future<String?> changePassword(String oldPw, String newPw) async {
    if (!checkPassword(oldPw)) return 'كلمة المرور الحالية غير صحيحة';
    if (newPw.length < 6) return 'كلمة المرور الجديدة 6 أحرف على الأقل';
    _pwHash = _hash(newPw);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPw, _pwHash);
    notifyListeners();
    return null;
  }

  /// حفظ المنتجات المنشورة على الموقع (القادمة من API المزامنة)
  Future<void> setRemoteProducts(List<Product> items) async {
    remoteProducts = items;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kRemote, Product.encodeList(items));
    notifyListeners();
  }

  /// تحديث عدد الطلبات المعلّقة القادم من الموقع
  Future<void> setPendingOrders(int n) async {
    pendingOrders = n;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kOrders, n);
    notifyListeners();
  }

  Future<void> markAllSynced(String when) async {
    for (final p in products) { p.synced = true; }
    lastSync = when;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastSync, when);
    await _save(sp);
    notifyListeners();
  }
}
