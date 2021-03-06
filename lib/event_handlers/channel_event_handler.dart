import '../pusher.dart';
import 'pusher_event_handler.dart';

class ChannelEventHandler implements PusherEventHandler {
  void handle(
    Pusher pusher,
    String channelName,
    String type,
    String event,
    String body,
    Function function,
  ) {
    function(new PusherMessage(channelName, event, body));
  }
}