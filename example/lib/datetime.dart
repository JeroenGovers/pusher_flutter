import 'package:flutter/widgets.dart';

class DateTimeFormatter extends StatelessWidget {
  final DateTime datetime;

  DateTimeFormatter(this.datetime);

  String _addLeadingZeros(int number, {int amount: 2}) {
    String text = number.toString();

    for(var i = text.length; i< amount; i++){
      text = '0' + text;
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    String text = _addLeadingZeros(datetime.hour) + ':' + _addLeadingZeros(datetime.minute) + ':' + _addLeadingZeros(datetime.second) + '.' + _addLeadingZeros(datetime.millisecond, amount: 3) + _addLeadingZeros(datetime.microsecond, amount: 3) + ' ' + _addLeadingZeros(datetime.day) + '-' + _addLeadingZeros(datetime.month) + '-' + _addLeadingZeros(datetime.year);

    return Text(text);
  }
}
