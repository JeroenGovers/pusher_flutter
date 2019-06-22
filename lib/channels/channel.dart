import 'dart:convert';

import 'package:pusher/event_handlers/channel_event_handler.dart';
import 'package:pusher/event_handlers/channel_state_change.dart';
import 'package:pusher/event_handlers/channel_subscription_succeeded.dart';
import 'package:web_socket_channel/io.dart';

import '../pusher.dart';

enum PusherChannelState {
  initial,
  subscribe_sent,
  subscribed,
  unsubscribed,
  failed,
}

abstract class Channel {
  final Pusher _pusher;
  final IOWebSocketChannel _webSocketChannel;
  final String _channelName;
  PusherChannelState _state = PusherChannelState.initial;

  Channel(this._pusher, this._webSocketChannel, this._channelName);

  void subscribe() {
    _setState(PusherChannelState.subscribe_sent);

    _webSocketChannel.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': {
        'channel': _channelName
      }
    }));
  }

  bool isSubscribed(){
    return _state == PusherChannelState.subscribed;
  }

  void unsubscribe() {
    _pusher.unsubscribe(_channelName);

    _setState(PusherChannelState.unsubscribed);
  }

  void addEventHandler(String event, Function(PusherMessage) onEvent) {
    _pusher.addEventHandler(_channelName, event, onEvent, ChannelEventHandler());
  }

  void removeEventHandler(String event) {
    _pusher.removeEventHandler(_channelName, event);
  }

  void onSubscriptionSucceeded(Function(PusherMessage) onSubscriptionSucceeded) {
    _setState(PusherChannelState.subscribed);

    _pusher.addEventHandler(_channelName, 'pusher_internal:subscription_succeeded', onSubscriptionSucceeded, ChannelSubscriptionSucceeded());
  }

  void onStateChange(Function(PusherMessage) onStateChange) {
    _pusher.addEventHandler(_channelName, 'pusher_internal:state', onStateChange, ChannelStateChange());
  }

  void _setState(PusherChannelState state){
    _state = state;

    _pusher.triggerHandler(_channelName, 'pusher_internal:state', {
      'state': state
    });
  }
}
