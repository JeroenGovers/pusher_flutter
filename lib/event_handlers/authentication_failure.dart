import '../pusher.dart';
import 'pusher_event_handler.dart';

class AuthenticationFailure implements PusherEventHandler {
  void handle(
    Pusher pusher,
    String channelName,
    String event,
    Map body,
    Function function,
  ) {
    function(channelName, event, body);
  }
}