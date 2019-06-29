import 'package:flutter/foundation.dart';

class LogNotifier with ChangeNotifier {
  List _list = [];

  List get list => _list;
  int get newLength => _list.length;

  void add(String type, String message) {
    _list.insert(0, {
      'type': type,
      'message': message,
      'datetime': new DateTime.now()
    });

    notifyListeners();
  }
}
