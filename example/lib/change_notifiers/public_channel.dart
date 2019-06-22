import 'package:flutter/foundation.dart';

class PublicChannelProvider with ChangeNotifier{
  Map<String, Map<String, List>> _map = {};

  Map<String, Map<String, List>> get list => _map;
  int get newLength => _map.length;

  void add(String channelName, String event) {
    if(!_map.containsKey(channelName)){
      _map[channelName] = {};
    }
    if(!_map[channelName].containsKey(event)){
      _map[channelName][event] = [];

      notifyListeners();
    }
  }
  void remove(String channelName, {String event}) {
    if(event != null){
      _map[channelName].remove(event);
    }
    else{
      _map[channelName] = {};
    }

    if(_map[channelName].length == 0){
      _map.remove(channelName);
    }

    notifyListeners();
  }
}