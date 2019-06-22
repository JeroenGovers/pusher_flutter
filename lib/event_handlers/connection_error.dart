import 'dart:convert';
import '../pusher.dart';
import 'pusher_event_handler.dart';

class ConnectionError implements PusherEventHandler {
  void handle(
    Pusher pusher,
    String channelName,
    String event,
    Map body,
    Function function,
  ) {
    function(PusherError(body['code'], body['message']));
  }
}