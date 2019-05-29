import '../pusher.dart';
import 'pusher_event_handler.dart';

class ChannelSubscriptionSucceeded implements PusherEventHandler {
  void handle(
    Pusher pusher,
    String channelName,
    String type,
    String event,
    String body,
    Function function,
  ) {
    function(channelName, type, body);
  }
}