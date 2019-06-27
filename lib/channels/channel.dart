import 'dart:convert';

import 'package:pusher/event_handlers/channel_event_handler.dart';
import 'package:pusher/event_handlers/channel_state_change.dart';
import 'package:pusher/event_handlers/channel_subscription_succeeded.dart';
import 'package:pusher/src/channel_manager.dart';

import '../pusher.dart';

enum PusherChannelState {
  initial,
  authorizing,
  authorized,
  not_authorized,
  subscribe_sent,
  subscribed,
  unsubscribed,
  failed,
}

abstract class Channel {
  final ChannelManager _channelManager;
  final String _channelName;

  Channel(this._channelName, this._channelManager);

  bool isSubscribed(){
    return getState == PusherChannelState.subscribed;
  }

  PusherChannelState getState(){
    return _channelManager.getChannelState(_channelName);
  }

  void unsubscribe() {
    _channelManager.unsubscribe(_channelName);
  }

  void addEventHandler(String event, Function(PusherMessage) onEvent) {
    _channelManager.addEventHandler(_channelName, event, onEvent, ChannelEventHandler());
  }

  void removeEventHandler(String event) {
    _channelManager.removeEventHandler(_channelName, event);
  }

  void onSubscriptionSucceeded(Function(PusherMessage) onSubscriptionSucceeded) {
    _channelManager.addEventHandler(_channelName, 'pusher_internal:subscription_succeeded', onSubscriptionSucceeded, ChannelSubscriptionSucceeded());
  }

  void onStateChange(Function(PusherMessage) onStateChange) {
    _channelManager.addEventHandler(_channelName, 'pusher_internal:state', onStateChange, ChannelStateChange());
  }
}
