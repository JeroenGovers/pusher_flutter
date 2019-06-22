import '../pusher.dart';
import 'pusher_event_handler.dart';

class ChannelStateChange implements PusherEventHandler {
  void handle(
    Pusher pusher,
    String channelName,
    String event,
    Map body,
    Function function,
  ) {
    function(new PusherMessage(channelName, event, body));
  }
}