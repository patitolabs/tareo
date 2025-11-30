import 'package:intl/intl.dart';

String formatDateTimeForPocketBase(DateTime dateTime) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toUtc());
}
