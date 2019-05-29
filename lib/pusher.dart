import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

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
  static const MethodChannel _methodChannel = const MethodChannel('flutter.jeroengovers.nl/pusher');
  static const EventChannel _eventChannel = const EventChannel('flutter.jeroengovers.nl/pusher/event');
  PusherConnectionState _state;
  Map<String, Map<String, dynamic>> _eventChannelFunctions = {};
  String _socketId = '';

  Pusher({
    @required String apiKey,
    String host,
    String cluster,
    bool encrypted,
    int port,
    int activityTimeout,
    int pongTimeout,
    int maxReconnectionAttempts,
    int maxReconnectGapInSeconds,
    String authorizer,
    Function(Pusher) onConnectionStateChange,
    Function(PusherError) onConnectionError,
  }) {
    var args = <String, dynamic>{
      'apiKey': apiKey,
    };
    if (cluster != null) {
      args["cluster"] = cluster;
    }
    if (host != null) {
      args["host"] = host;
    }
    if (encrypted != null) {
      args["encrypted"] = encrypted;
    }
    if (port != null) {
      args["port"] = port;
    }
    if (activityTimeout != null) {
      args["activityTimeout"] = activityTimeout;
    }
    if (pongTimeout != null) {
      args["pongTimeout"] = pongTimeout;
    }
    if (maxReconnectionAttempts != null) {
      args["maxReconnectionAttempts"] = maxReconnectionAttempts;
    }
    if (maxReconnectGapInSeconds != null) {
      args["maxReconnectGapInSeconds"] = maxReconnectGapInSeconds;
    }
    if (authorizer != null) {
      args["authorizer"] = authorizer;
    }

    if (onConnectionStateChange != null) {
      _registerEvent(
        '_connection',
        'state',
        'change',
        onConnectionStateChange,
        ConnectionStateChange(),
      );
    }

    if (onConnectionError != null) {
      _registerEvent(
        '_connection',
        'error',
        'error',
        onConnectionError,
        ConnectionError(),
      );
    }

    _methodChannel.invokeMethod('create', args);

    _eventChannel.receiveBroadcastStream().listen((dynamic map) {
      if (map is Map) {
        final channelName = map['channel'];
        final type = map['type'];
        final event = map['event'];
        final body = map['body'];

        print(channelName + '.' + type + '.' + event + ' : ' + body);

        if (channelName == '_connection' && type == 'state' && event == 'change') {
          final connectionStateBody = jsonDecode(body);

          _state = _connectivityStringToState(connectionStateBody['state']);
          _socketId = connectionStateBody['socketId'];
        }

        Map<String, dynamic> eventHandler = _eventChannelFunctions[channelName + '.' + type + '.' + event] ?? null;

        if (eventHandler != null) {
          PusherEventHandler handler = eventHandler['handler'];
          Function function = eventHandler['function'];

          handler.handle(this, channelName, type, event, body, function);
        }
      }

      return null;
    });
  }

  void connect() {
    _methodChannel.invokeMethod('connect');
  }

  bool isConnected(){
    return getState() == PusherConnectionState.connected;
  }

  void disconnect() {
    _methodChannel.invokeMethod('disconnect');
  }

  String getSocketId(){
    return _socketId;
  }

  PusherConnectionState getState() {
    return _state;
  }

  PusherConnectionState _connectivityStringToState(dynamic string) {
    switch (string) {
      case 'connecting':
        return PusherConnectionState.connecting;
      case 'connected':
        return PusherConnectionState.connected;
      case 'disconnected':
        return PusherConnectionState.disconnected;
      case 'disconnecting':
        return PusherConnectionState.disconnecting;
      case 'reconnecting':
        return PusherConnectionState.reconnecting;
      case 'reconnectingWhenNetworkBecomesReachable':
        return PusherConnectionState.reconnectingWhenNetworkBecomesReachable;
    }
    return PusherConnectionState.disconnected;
  }

  void subscribe({
    @required String channelName,
    @required dynamic event,
    @required Function(PusherMessage) onEvent,
    Function(PusherMessage) onSubscriptionSucceeded,
  }) {
    this._subscribeTo(
      type: 'subscribe',
      channelName: channelName,
      event: event,
      onEvent: onEvent,
      onSubscriptionSucceeded: onSubscriptionSucceeded,
      onAuthenticationFailure: null,
    );
  }

  void subscribePrivate({
    @required String channelName,
    @required dynamic event,
    @required Function(PusherMessage) onEvent,
    Function(PusherMessage) onSubscriptionSucceeded,
    Function(PusherMessage) onAuthenticationFailure,
  }) {
    this._subscribeTo(
      type: 'subscribePrivate',
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
    _methodChannel.invokeMethod('subscribePresence', {
      "channel": channelName,
      "event": event
    });
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
      _methodChannel.invokeMethod(
        type,
        {
          "channel": channelName,
          "event": event,
        },
      );

      _registerEvent(channelName, 'event', event, onEvent, ChannelEventHandler());

      if (onSubscriptionSucceeded != null) {
        _registerEvent(channelName, 'subscription-succeeded', event, onSubscriptionSucceeded, ChannelSubscriptionSucceeded());
      }

      if (onAuthenticationFailure != null) {
        _registerEvent(channelName, 'subscription-failure', event, onAuthenticationFailure, AuthenticationFailure());
      }
    });
  }

  void trigger(String channelName, String event, String data) {
    _methodChannel.invokeMethod('trigger', {
      "channel": channelName,
      "event": event,
      "data": data
    });
  }

  void _registerEvent(String channelName, String type, String event, Function function, PusherEventHandler handler) {
    _eventChannelFunctions[channelName + '.' + type + '.' + event] = {
      'function': function,
      'handler': handler,
    };
  }
}

class PusherError {
  String code;
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
  final String body;

  PusherMessage(this.channelName, this.eventName, this.body);
}
