import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'store.dart';

/// خدمة المزامنة مع موقع دهفة الحي (واجهة v1.9):
///   POST {base}/api/sync/push  {key, products:[...]}   ← رفع المنتجات المحلية غير المتزامنة
///   GET  {base}/api/sync/pull?key=...                  ← سحب طلبات المحفظة المعلّقة
/// بدون مفتاح: تعمل بوضع محاكاة آمن محلياً (لا تُفقد أي بيانات).
class SyncService {
  static const _kBase = 'dhfa_sync_base';
  static const _kKey = 'dhfa_sync_key';

  String baseUrl = 'https://dhfa-production.up.railway.app';
  String apiKey = '';

  /// استعادة الإعدادات المحفوظة (تُستدعى عند إقلاع التطبيق)
  Future<void> restore() async {
    final sp = await SharedPreferences.getInstance();
    baseUrl = sp.getString(_kBase) ?? baseUrl;
    apiKey = sp.getString(_kKey) ?? '';
  }

  Future<void> saveSettings(String base, String key) async {
    baseUrl = base.trim().isEmpty ? baseUrl : base.trim();
    apiKey = key.trim();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kBase, baseUrl);
    await sp.setString(_kKey, apiKey);
  }

  String get mode => apiKey.isEmpty ? 'محاكاة (بدون مفتاح)' : 'فعلية مع الموقع';

  /// رفع المنتجات غير المتزامنة — تظهر في لوحة الموقع «بانتظار المراجعة»
  Future<String> pushPending(LocalStore store) async {
    final pending = store.products.where((p) => !p.synced).toList();
    if (pending.isEmpty) return 'لا يوجد ما يُرفع — كل شيء متزامن ✓';
    if (apiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      await store.markAllSynced(_now());
      return 'تمت المزامنة محلياً ✓ (وضع المحاكاة — أدخل المفتاح لتفعيل الرفع الحقيقي)';
    }
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/sync/push'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': apiKey, 'products': pending.map((e) => e.toJson()).toList(),
          'ads': store.ads.map((e) => e.toJson()).toList()}),
      ).timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        await store.markAllSynced(_now());
        return 'رُفع ${body['inserted'] ?? pending.length} منتجاً — بانتظار مراجعتك في لوحة الموقع ✓';
      }
      if (res.statusCode == 401) return 'المفتاح غير صحيح — تحقق منه وأعد المحاولة';
      if (res.statusCode == 503) return 'لم يُضبط مفتاح المزامنة في الموقع بعد (DHFA_SYNC_API_KEY)';
      return 'تعذّر الرفع (رمز ${res.statusCode}) — أعِد المحاولة';
    } catch (_) {
      return 'لا يوجد اتصال — ستتزامن تلقائياً عند عودته';
    }
  }

  /// سحب عدد طلبات المحفظة المعلّقة من الموقع (null = تعذر الجلب)
  Future<int?> fetchPendingOrders(LocalStore store) async {
    if (apiKey.isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/sync/pull?key=${Uri.encodeComponent(apiKey)}'),
      ).timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final n = (body['pending_orders'] as num?)?.toInt();
        if (n != null) await store.setPendingOrders(n);
        final ords = ((body['orders'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await store.setRemoteOrders(ords);
        return n;
      }
    } catch (_) {/* صامت: تبقى القيمة المحلية */}
    return null;
  }

  /// سحب المنتجات المنشورة على الموقع (الكتب والدورات) — تُحفظ وتُعرض في التطبيق
  Future<int?> fetchProducts(LocalStore store) async {
    if (apiKey.isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/sync/products?key=${Uri.encodeComponent(apiKey)}'),
      ).timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['products'] as List?) ?? [];
        final items = list.map((e) => Product.fromJson({
              'id': 'site-${e['id']}',
              'title': e['title'],
              'price': e['price'],
              'section': _sectionOf(e['section']?.toString() ?? ''),
              'emoji': '📚',
              'desc': e['description']?.toString() ?? '',
              'remoteImage': e['image']?.toString() ?? '',
              'isRemote': true,
              'synced': true,
            })).toList();
        final rAds = ((body['ads'] as List?) ?? []).map((e) => Ad(
              id: 'r${e['id']}', title: (e['title'] ?? '').toString(),
              emoji: '📣', badge: (e['badge'] ?? '').toString(),
              imagePath: (e['image'] ?? '').toString())).toList();
        final cats = ((body['categories'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final cops = ((body['coupons'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await store.setRemoteData(items, rAds, cats, cops);
        return items.length;
      }
    } catch (_) {/* صامت */}
    return null;
  }

  static String _sectionOf(String s) {
    if (s.contains('دورة')) return 'دورات';
    if (s.contains('قالب')) return 'قوالب';
    if (s.contains('مجاني')) return 'مجاني';
    return 'كتب';
  }

  String _now() {
    final n = DateTime.now();
    return 'اليوم ${n.hour}:${n.minute.toString().padLeft(2, '0')}';
  }
}
