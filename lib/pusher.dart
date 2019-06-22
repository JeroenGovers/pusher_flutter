import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pusher/channels/public.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'channels/channel.dart';
import 'event_handlers/authentication_failure.dart';
import 'event_handlers/channel_event_handler.dart';
import 'event_handlers/channel_subscription_succeeded.dart';
import 'event_handlers/connection_error.dart';
import 'event_handlers/connection_state_change.dart';
import 'event_handlers/pusher_event_handler.dart';

class PusherEventException implements Exception {
  String errMsg() => 'Event should be of type String or type List';
}

enum PusherConnectionState {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
  reconnectingWhenNetworkBecomesReachable,
}

class Pusher {
  static const String PUSHER_DOMAIN = 'pusher.com';
  static const String PRIVATE_PREFIX = 'private-';
  static const String PRESENCE_PREFIX = 'presence-';

  String _url;
  String _authorizer;
  IOWebSocketChannel _webSocketChannel;
  PusherConnectionState _state;
  Map<String, Channel> _channels = {};
  Map<String, Map<String, Map<String, dynamic>>> _eventChannelFunctions = {};
  String _socketId = '';

  Pusher({
    @required String apiKey,
    String host: 'ws.' + PUSHER_DOMAIN,
    String cluster,
    bool encrypted: true,
    int port: 443,
    int activityTimeout: 120000,
    int pongTimeout: 30000,
    int maxReconnectionAttempts: 6,
    int maxReconnectGapInSeconds: 30,
    String authorizer,
    Function(Pusher) onConnectionStateChange,
    Function(PusherError) onConnectionError,
  }) {
    var args = <String, dynamic>{
      'apiKey': apiKey,
      'host': host,
    };

    if (cluster != null) {
      host = 'ws-' + cluster + '.' + PUSHER_DOMAIN;
    }

    args["encrypted"] = encrypted;
    args["port"] = port;
    _url = 'ws';
    if (encrypted) {
      _url += 'wss';
    }
    _url += '://' + host;
    _url += ':' + port.toString();
    _url += '/app/';
    _url += apiKey;
    _url += '?client=flutter&protocol=5&version=1';

    //TODO: implement this
    // args["activityTimeout"] = activityTimeout;
    // args["pongTimeout"] = pongTimeout;
    // args["maxReconnectionAttempts"] = maxReconnectionAttempts;
    // args["maxReconnectGapInSeconds"] = maxReconnectGapInSeconds;

    if (authorizer != null) {
      _authorizer = authorizer;
    }

    if (onConnectionStateChange != null) {
      addEventHandler(
        'pusher:connection',
        'state',
        onConnectionStateChange,
        ConnectionStateChange(),
      );
    }

    if (onConnectionError != null) {
      addEventHandler(
        'pusher:connection',
        'error',
        onConnectionError,
        ConnectionError(),
      );
    }

    // _methodChannel.invokeMethod('create', args);

    // _eventChannel.receiveBroadcastStream().listen((dynamic map) {
    //   if (map is Map) {
    //     final channelName = map['channel'];
    //     final type = map['type'];
    //     final event = map['event'];
    //     final body = map['body'];

    //     print(channelName + '.' + type + '.' + event + ' : ' + body);

    //     if (channelName == 'pusher:connection' && type == 'state' && event == 'change') {
    //       final connectionStateBody = jsonDecode(body);

    //       _state = _connectivityStringToState(connectionStateBody['state']);
    //       _socketId = connectionStateBody['socketId'];
    //     }

    //     Map<String, dynamic> eventHandler = _eventChannelFunctions[channelName + '.' + type + '.' + event] ?? null;

    //     if (eventHandler != null) {
    //       PusherEventHandler handler = eventHandler['handler'];
    //       Function function = eventHandler['function'];

    //       handler.handle(this, channelName, type, event, body, function);
    //     }
    //   }

    //   return null;
    // });
  }

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

  bool isConnected() {
    return getState() == PusherConnectionState.connected;
  }

  void disconnect() {
    if (_state == PusherConnectionState.connected) {
      _setState(PusherConnectionState.disconnecting);
    }

    _webSocketChannel.sink.close(status.goingAway);
    _webSocketChannel = null;

    _setState(PusherConnectionState.disconnected);
  }

  String getSocketId() {
    return _socketId;
  }

  PusherConnectionState getState() {
    return _state;
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
        'state': state
      },
    );
  }

  void triggerHandler(String channelName, String event, Map data) {
    Map<String, dynamic> eventHandler = _eventChannelFunctions[channelName][event] ?? null;

    if (eventHandler != null) {
      PusherEventHandler handler = eventHandler['handler'];
      Function function = eventHandler['function'];

      handler.handle(this, channelName, event, data, function);
    }

    return null;
  }

  PublicChannel subscribe({
    @required String channelName,
    @required dynamic event,
    @required Function(PusherMessage) onEvent,
    Function(PusherMessage) onStateChange,
    Function(PusherMessage) onSubscriptionSucceeded,
  }) {
    if (channelName.startsWith(PRIVATE_PREFIX)) {
      throw new Exception('Please use the subscribePrivate method');
    } else if (channelName.startsWith(PRESENCE_PREFIX)) {
      throw new Exception('Please use the subscribePresence method');
    }

    PublicChannel channel = getChannel(channelName);
    if (channel == null) {
      channel = PublicChannel(this, _webSocketChannel, channelName);
      channel.subscribe();

      _channels[channelName] = channel;
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

  PublicChannel getChannel(String channelName) {
    if (channelName.startsWith(PRIVATE_PREFIX)) {
      throw new Exception('Please use the getPrivateChannel method');
    } else if (channelName.startsWith(PRESENCE_PREFIX)) {
      throw new Exception('Please use the getPresenceChannel method');
    }

    if (_channels.containsKey(channelName)) {
      return _channels[channelName];
    }

    return null;
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
  }

  void subscribePrivate({
    @required String channelName,
    @required dynamic event,
    @required Function(PusherMessage) onEvent,
    Function(PusherMessage) onSubscriptionSucceeded,
    Function(PusherMessage) onAuthenticationFailure,
  }) {
    this._subscribeTo(
      type: 'subscribe-private',
      channelName: channelName,
      event: event,
      onEvent: onEvent,
      onSubscriptionSucceeded: onSubscriptionSucceeded,
      onAuthenticationFailure: onAuthenticationFailure,
    );
  }

  void subscribePresence({
    @required String channelName,
    @required dynamic event,
    @required Function(PusherMessage) onEvent,
    Function(PusherMessage) onSubscriptionSucceeded,
    Function(PusherMessage) onAuthenticationFailure,
  }) {
    // _methodChannel.invokeMethod('subscribePresence', {
    //   "channel": channelName,
    //   "event": event
    // });
  }

  void _subscribeTo({
    @required String type,
    @required String channelName,
    @required dynamic event,
    @required Function(PusherMessage) onEvent,
    Function(PusherMessage) onSubscriptionSucceeded,
    Function(PusherMessage) onAuthenticationFailure,
  }) {
    if (event is String)
      event = [
        event.toString()
      ];
    if (!(event is List<String>)) {
      throw new PusherEventException();
    }

    event.forEach((dynamic event) {
      _webSocketChannel.sink.add(jsonEncode({
        'event': 'pusher:subscribe',
        'data': {
          'channel': channelName
        }
      }));

      addEventHandler(channelName, event, onEvent, ChannelEventHandler());

      if (onSubscriptionSucceeded != null) {
        addEventHandler(channelName, 'pusher_internal:subscription_succeeded', onSubscriptionSucceeded, ChannelSubscriptionSucceeded());
      }

      if (onAuthenticationFailure != null) {
        addEventHandler(channelName, 'subscription-failure', onAuthenticationFailure, AuthenticationFailure());
      }
    });
  }

  //TODO: trigger maken
  void trigger(String channelName, String event, String data) {
    // _methodChannel.invokeMethod('trigger', {
    //   "channel": channelName,
    //   "event": event,
    //   "data": data
    // });
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

class PusherError {
  int code;
  String message;

  PusherError(this.code, this.message);

  PusherError.fromJson(Map<String, dynamic> json)
      : code = json['code'],
        message = json['message'];

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message
      };
}

class PusherMessage {
  final String channelName;
  final String eventName;
  final Map body;

  PusherMessage(this.channelName, this.eventName, this.body);
}
