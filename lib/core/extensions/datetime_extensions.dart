import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('dd/MM/yyyy').format(this);
  }

  String get chatTime {
    if (isToday) return DateFormat('HH:mm').format(this);
    if (isYesterday) return 'أمس';
    return DateFormat('dd/MM/yyyy').format(this);
  }

  String get fullDate => DateFormat('EEEE، d MMMM yyyy', 'ar').format(this);
  String get timeOnly => DateFormat('HH:mm').format(this);
  String get dateOnly => DateFormat('dd/MM/yyyy').format(this);
}
