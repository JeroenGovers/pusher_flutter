import 'package:flutter/foundation.dart';
import 'package:pusher/pusher.dart';

class PusherStateNotifier with ChangeNotifier{
  PusherConnectionState _state = PusherConnectionState.disconnected;

  PusherConnectionState get state => _state;

  set state(PusherConnectionState newState){
    _state = newState;

    notifyListeners();
  }
}