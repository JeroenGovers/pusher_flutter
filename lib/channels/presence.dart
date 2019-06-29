import 'package:pusher/channels/private.dart';
import 'package:pusher/event_handlers/member_added.dart';
import 'package:pusher/event_handlers/member_removed.dart';
import 'package:pusher/src/channel_manager.dart';

import '../pusher.dart';

class PresenceChannel extends PrivateChannel{
  PresenceChannel(String channelName, ChannelManager channelManager) : super(channelName, channelManager);

  //TODO: getUsers

  //TODO: getMe


  void onMemberAdded(Function(PusherMessage) onSubscriptionSucceeded) {
    getChannelManager().addEventHandler(this.getName(), 'pusher_internal:member_added', onSubscriptionSucceeded, MemberAdded());
  }

  void onMemberRemoved(Function(PusherMessage) onStateChange) {
    getChannelManager().addEventHandler(this.getName(), 'pusher_internal:member_removed', onStateChange, MemberRemoved());
  }
}