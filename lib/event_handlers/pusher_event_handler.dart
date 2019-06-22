import 'package:pusher/pusher.dart';

abstract class PusherEventHandler {
  void handle(
    Pusher pusher,
    String channelName,
    String event,
    Map body,
    Function function,
  );
}