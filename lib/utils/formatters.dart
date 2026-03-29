import 'package:intl/intl.dart';

final currencyFmt =
    NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

final dateFmt = DateFormat('dd/MM/yyyy');
final dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');
final monthFmt = DateFormat('MMM yyyy', 'es_MX');
