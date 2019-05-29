import 'package:pusher/pusher.dart';

abstract class PusherEventHandler {
  void handle(
    Pusher pusher,
    String channelName,
    String type,
    String event,
    String body,
    Function function,
  );
}