import 'package:pusher/channels/private.dart';
import 'package:pusher/src/channel_manager.dart';

class PresenceChannel extends PrivateChannel{
  PresenceChannel(String channelName, ChannelManager channelManager) : super(channelName, channelManager);
}