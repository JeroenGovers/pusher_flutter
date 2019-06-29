import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:pusher/channels/channel.dart';
import 'package:pusher/channels/presence.dart';
import 'package:pusher/channels/private.dart';
import 'package:pusher/channels/public.dart';
import 'package:pusher/event_handlers/channel_state_change.dart';
import 'package:pusher/event_handlers/pusher_event_handler.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../authorizer.dart';
import '../pusher.dart';

class ChannelManager {
  final Pusher _pusher;
  final String _url;
  final PusherAuthorizer _authorizer;
  PusherConnectionState _state;
  String _socketId;
  IOWebSocketChannel _webSocketChannel;
  Map<String, Map<String, Map<String, dynamic>>> _eventChannelFunctions = {};
  Map<String, Channel> _channels = {};
  Map<String, PusherChannelState> _channelStates = {};

  ChannelManager(this._pusher, this._url, this._authorizer);

  void connect() {
    _setState(PusherConnectionState.connecting);

    _webSocketChannel = IOWebSocketChannel.connect(_url);
    _webSocketChannel.stream.listen(
      _connectionListener,
      onError: (error) {
        _connectionError(0, error.message);
      },
      cancelOnError: true,
    );
  }

  void disconnect() {
    if (_state == PusherConnectionState.connected) {
      _setState(PusherConnectionState.disconnecting);
    }

    _webSocketChannel.sink.close(status.goingAway);
    _webSocketChannel = null;

    _setState(PusherConnectionState.disconnected);
  }

  void _connectionListener(Object message) {
    final map = Map<String, dynamic>.from(jsonDecode(message));
    final String event = map['event'];
    Map<String, dynamic> data = {};

    if (map.containsKey('data')) {
      if (!(map['data'] is Map)) {
        map['data'] = Map<String, dynamic>.from(jsonDecode(map['data']));
      }
      data = map['data'];
    }

    print({
      'map': map.toString(),
      'data': data.toString()
    }.toString());

    switch (event) {
      case 'pusher:connection_established':
        _socketId = data['socket_id'];
        _setState(PusherConnectionState.connected);

        break;
      case 'pusher:error':
        _connectionError(data['code'], data['message']);
        break;
      case 'pusher_internal:subscription_succeeded':
        _setChannelState(map['channel'], PusherChannelState.subscribed);
        break;
      default:
        print('default');
        triggerHandler(map['channel'], event, data);
    }
  }

  void _connectionError(int code, String message) {
    _setState(PusherConnectionState.disconnected);

    triggerHandler(
      'pusher:connection',
      'error',
      {
        'code': code,
        'message': message,
      },
    );
  }

  void triggerHandler(String channelName, String event, Map data) {
    print(channelName + ': ' + event);
    print(data);

    if (_eventChannelFunctions.containsKey(channelName) && _eventChannelFunctions[channelName].containsKey(event)) {
      Map<String, dynamic> eventHandler = _eventChannelFunctions[channelName][event];
      PusherEventHandler handler = eventHandler['handler'];
      Function function = eventHandler['function'];

      handler.handle(_pusher, channelName, event, data, function);
    }

    return null;
  }

  void trigger(String channelName, String event, String data) {
    _webSocketChannel.sink.add(jsonEncode({
      'channel': channelName,
      'event': event,
      'data': data,
    }));
  }

  PusherConnectionState getState() {
    return _state;
  }

  String getSocketId() {
    return _socketId;
  }

  void _setState(PusherConnectionState state) {
    _state = state;

    if (state != PusherConnectionState.connected) {
      _socketId = '';
    }

    triggerHandler(
      'pusher:connection',
      'state',
      {
        'state': state,
        'socket_id': _socketId,
      },
    );
  }

  Channel subscribe(String channelName, dynamic event, Function(PusherMessage) onEvent, Function(PusherMessage) onStateChange, Function(PusherMessage) onSubscriptionSucceeded, {Function(PusherMessage) onAuthenticationFailure}) {
    Channel channel = getChannel(channelName);
    if (channel == null) {
      if (channelName.startsWith(Pusher.PRIVATE_PREFIX)) {
        channel = PrivateChannel(channelName, this);
      } else if (channelName.startsWith(Pusher.PRESENCE_PREFIX)) {
        channel = PresenceChannel(channelName, this);
      } else {
        channel = PublicChannel(channelName, this);
      }

      _channels[channelName] = channel;
      _channelStates[channelName] = PusherChannelState.initial;

      _subscribeToChannel(channelName);
    }

    channel.addEventHandler(event, onEvent);

    if (onStateChange != null) {
      channel.onStateChange(onStateChange);
    }
    if (onSubscriptionSucceeded != null) {
      channel.onSubscriptionSucceeded(onSubscriptionSucceeded);
    }

    return channel;
  }

  void _subscribeToChannel(String channelName) async {
    bool authorize = channelName.startsWith(Pusher.PRIVATE_PREFIX) || channelName.startsWith(Pusher.PRESENCE_PREFIX);

    Map webSocketChannelData = {
      'channel': channelName
    };

    if (authorize) {
      _setChannelState(channelName, PusherChannelState.authorizing);

      String webSocketChannelAuth = await _authorizer.authorize(channelName, _socketId);
      if (webSocketChannelAuth.isEmpty) {
        _setChannelState(channelName, PusherChannelState.not_authorized);

        return null;
      }
      webSocketChannelData['auth'] = webSocketChannelAuth;

      _setChannelState(channelName, PusherChannelState.authorized);
    }

    _webSocketChannel.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': webSocketChannelData
    }));

    _setChannelState(channelName, PusherChannelState.subscribe_sent);
  }

  Channel getChannel(String channelName) {
    if (_channels.containsKey(channelName)) {
      return _channels[channelName];
    }

    return null;
  }

  PusherChannelState getChannelState(channelName) {
    if (_channels.containsKey(channelName)) {
      return _channelStates[channelName];
    }

    return null;
  }

  void _setChannelState(String channelName, PusherChannelState state) {
    if (_channelStates[channelName] != state) {
      print('channel state `$channelName`: $state');

      _channelStates[channelName] = state;

      triggerHandler(channelName, 'pusher_internal:state', {
        'state': state
      });

      if (state == PusherChannelState.subscribed) {
        triggerHandler(channelName, 'pusher_internal:subscription_succeeded', {});
      }
    }
  }

  void unsubscribe(String channelName) {
    _channels.remove(channelName);
    _eventChannelFunctions.remove(channelName);
    _webSocketChannel.sink.add(jsonEncode({
      'event': 'pusher:unsubscribe',
      'data': {
        'channel': channelName
      }
    }));

    _setChannelState(channelName, PusherChannelState.unsubscribed);
  }

  void addEventHandler(String channelName, String event, Function function, PusherEventHandler handler) {
    if (!_eventChannelFunctions.containsKey(channelName)) {
      _eventChannelFunctions[channelName] = {};
    }

    _eventChannelFunctions[channelName][event] = {
      'function': function,
      'handler': handler,
    };
  }

  void removeEventHandler(String channelName, String event) {
    _eventChannelFunctions[channelName]?.remove(event);
  }
}
