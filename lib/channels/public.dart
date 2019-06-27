import 'package:pusher/src/channel_manager.dart';

import 'channel.dart';

class PublicChannel extends Channel {
  PublicChannel(String channelName, ChannelManager channelManager) : super(channelName, channelManager);
}