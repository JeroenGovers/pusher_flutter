import 'package:pusher/channels/public.dart';
import 'package:pusher/src/channel_manager.dart';

class PrivateChannel extends PublicChannel{
  PrivateChannel(String channelName, ChannelManager channelManager) : super(channelName, channelManager);


}