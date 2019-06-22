import 'package:pusher/pusher.dart';

import 'package:web_socket_channel/io.dart';

import 'channel.dart';

class PublicChannel extends Channel{
  PublicChannel(Pusher pusher, IOWebSocketChannel webSocketChannel, String channelName) : super(pusher, webSocketChannel, channelName);
}