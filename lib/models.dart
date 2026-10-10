import 'dart:convert';

class Product {
  final String id;
  final String title;
  final int price; // بالريال اليمني
  final String section; // كتب / دورات / قوالب / مجاني
  final String emoji;
  final String desc;     // وصف مختصر (اختياري)
  final String fileUrl;  // رابط مباشر للملف (PDF)
  final String filePath; // مسار ملف مرفوع من الجهاز
  final String fileName; // اسم الملف المرفوع
  bool synced;

  Product({required this.id, required this.title, required this.price,
      required this.section, required this.emoji, this.desc = '',
      this.fileUrl = '', this.filePath = '', this.fileName = '', this.synced = true});

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'price': price,
    'section': section, 'emoji': emoji, 'synced': synced,
    'desc': desc, 'fileUrl': fileUrl, 'filePath': filePath, 'fileName': fileName,
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String, title: j['title'] as String,
    price: (j['price'] as num).toInt(), section: j['section'] as String,
    emoji: j['emoji'] as String? ?? '📦', synced: j['synced'] as bool? ?? true,
    desc: j['desc'] as String? ?? '',
    fileUrl: j['fileUrl'] as String? ?? '',
    filePath: j['filePath'] as String? ?? '',
    fileName: j['fileName'] as String? ?? '');

  bool get isFree => price == 0;
  bool get hasFile => fileUrl.isNotEmpty || filePath.isNotEmpty;

  static String encodeList(List<Product> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<Product> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// إعلان — يظهر في البانر المتحرك بالصفحة الرئيسية
class Ad {
  final String id;
  final String title;
  final String emoji;
  final String badge;
  const Ad({required this.id, required this.title, required this.emoji, required this.badge});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'emoji': emoji, 'badge': badge};

  factory Ad.fromJson(Map<String, dynamic> j) => Ad(
      id: j['id'] as String, title: j['title'] as String,
      emoji: j['emoji'] as String? ?? '📣', badge: j['badge'] as String? ?? 'جديد');

  static String encodeList(List<Ad> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<Ad> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Ad.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// طلب شراء — يُنشأ عند تأكيد الدفع بالمحفظة
class Order {
  final String id;
  final String productTitle;
  final int price;
  final String ref;   // الرقم المرجعي للتحويل
  final String time;
  String status;      // بانتظار التأكيد / تم التسليم

  Order({required this.id, required this.productTitle, required this.price,
      required this.ref, required this.time, this.status = 'بانتظار التأكيد'});

  Map<String, dynamic> toJson() => {
    'id': id, 'productTitle': productTitle, 'price': price,
    'ref': ref, 'time': time, 'status': status};

  factory Order.fromJson(Map<String, dynamic> j) => Order(
      id: j['id'] as String, productTitle: j['productTitle'] as String,
      price: (j['price'] as num).toInt(), ref: j['ref'] as String? ?? '',
      time: j['time'] as String? ?? '',
      status: j['status'] as String? ?? 'بانتظار التأكيد');

  static String encodeList(List<Order> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<Order> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }
}
