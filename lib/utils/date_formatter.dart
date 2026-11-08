import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dayDateFormat = DateFormat('EEEE, d MMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatFullDate(DateTime dateTime) {
    return _dayDateFormat.format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  static String formatDeadlineCountdown(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      final passed = now.difference(dueDate);
      if (passed.inDays > 0) {
        return 'Terlewat ${passed.inDays} hari';
      } else if (passed.inHours > 0) {
        return 'Terlewat ${passed.inHours} jam';
      } else {
        return 'Terlewat ${passed.inMinutes} menit';
      }
    }

    if (difference.inDays == 0) {
      if (dueDate.day == now.day) {
        if (difference.inHours > 0) {
          return 'Hari ini (${difference.inHours} jam lagi)';
        } else {
          return 'Hari ini (${difference.inMinutes} menit lagi)';
        }
      } else {
        return 'Besok, ${formatTime(dueDate)}';
      }
    } else if (difference.inDays == 1) {
      return 'Besok, ${formatTime(dueDate)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lagi';
    } else {
      return formatShortDate(dueDate);
    }
  }
}

