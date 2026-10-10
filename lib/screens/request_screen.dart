import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../sync_service.dart';

/// نافذة الطلب — تُرسل الطلب إلى موقع دهفة (نفس نموذج /services)
const List<String> kRequestKinds = [
  'تصميم عرض تقديمي (برزنتيشن) من محتوى العميل',
  'تدقيق وتنسيق بحث أو مذكرة',
  'قالب رقمي جاهز للتعديل',
  'بنك أسئلة محلولة للتدريب',
];

Future<void> showRequestDialog(BuildContext context, SyncService sync) async {
  final name = TextEditingController();
  final contact = TextEditingController();
  final message = TextEditingController();
  String kind = kRequestKinds[0];
  bool busy = false;

  await showDialog(context: context, builder: (ctx) {
    return StatefulBuilder(builder: (ctx, setSt) {
      return Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🙋 نافذة الطلب', style: TextStyle(fontWeight: FontWeight.w900, color: Dhfa.navy)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('اطلب واحنا نلبي', style: TextStyle(fontSize: 11.5, color: Dhfa.gold2, fontWeight: FontWeight.w700)),
          SizedBox(height: 10),
          _rqField(name, 'الاسم'),
          SizedBox(height: 8),
          _rqField(contact, 'وسيلة التواصل (واتساب/بريد)'),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(value: kind, isExpanded: true,
            decoration: _rqDec('نوع الطلب'),
            items: [for (final k in kRequestKinds) DropdownMenuItem(value: k, child: Text(k, style: TextStyle(fontSize: 12)))],
            onChanged: (v) => setSt(() => kind = v ?? kRequestKinds[0])),
          SizedBox(height: 8),
          _rqField(message, 'تفاصيل الطلب (10 أحرف على الأقل)', maxLines: 4),
        ])),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Dhfa.gold, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: busy ? null : () async {
              if (name.text.trim().length < 2 || contact.text.trim().length < 5 ||
                  message.text.trim().length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('تحقق من الاسم ووسيلة التواصل وتفاصيل الطلب (10 أحرف على الأقل)')));
                return;
              }
              setSt(() => busy = true);
              final ok = await _sendRequest(sync, name.text.trim(), contact.text.trim(), kind, message.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? '✅ وصل طلبك إلى دهفة — سنتواصل معك قريباً' : 'تعذّر الإرسال — تحقق من الاتصال وأعد المحاولة'),
                behavior: SnackBarBehavior.floating));
            },
            icon: Icon(Icons.send_rounded, size: 16),
            label: Text('إرسال الطلب', style: TextStyle(fontWeight: FontWeight.w900))),
        ],
      ));
    });
  });
}

TextField _rqField(TextEditingController c, String label, {int maxLines = 1}) =>
    TextField(controller: c, maxLines: maxLines, decoration: _rqDec(label));

InputDecoration _rqDec(String label) => InputDecoration(labelText: label,
  labelStyle: TextStyle(fontSize: 11.5, color: Dhfa.muted, fontWeight: FontWeight.w700),
  filled: true, fillColor: Color(0xFFFBFAF6),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFFE5E0D2))),
  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10));

/// إرسال الطلب إلى نموذج /services في الموقع (مع CSRF)
Future<bool> _sendRequest(SyncService sync, String name, String contact, String kind, String message) async {
  try {
    final base = sync.baseUrl;
    // 1) جلب الصفحة لاستخراج رمز CSRF
    final page = await http.get(Uri.parse('$base/services')).timeout(const Duration(seconds: 20));
    final m = RegExp(r'name="csrf_token"[^>]*value="([^"]+)"').firstMatch(page.body);
    if (m == null) return false;
    final csrf = m.group(1)!;
    // 2) إرسال الطلب (form-encoded مثل النموذج)
    final res = await http.post(Uri.parse('$base/services'), headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'csrf_token': csrf,
      'website': '',
      'full_name': name,
      'contact': contact,
      'service_kind': kind,
      'message': message,
    }).timeout(const Duration(seconds: 25));
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}
