import 'dart:async';

import 'package:flutter/services.dart';

enum PusherConnectionState {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
  reconnectingWhenNetworkBecomesReachable
}

class Pusher {
  static const MethodChannel _channel = const MethodChannel('flutter.jeroengovers.nl/pusher');
  static const EventChannel _connectivityEventChannel = const EventChannel('flutter.jeroengovers.nl/pusher/connection');
  static const EventChannel _messageChannel = const EventChannel('flutter.jeroengovers.nl/pusher/message');

  Pusher(String apiKey, {String cluster, String host, bool encrypted, int port, int activityTimeout, int pongTimeout, int maxReconnectionAttempts, int maxReconnectGapInSeconds, String authorizer}){
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
    _channel.invokeMethod('create', args);
  }

  void connect() {
    _channel.invokeMethod('connect');
  }

  Stream<PusherConnectionState> get onConnectivityChanged =>
      _connectivityEventChannel
          .receiveBroadcastStream()
          .map(_connectivityStringToState);

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

  void subscribe(String channelName, String event) {
    _channel.invokeMethod('subscribe', {"channel": channelName, "event": event});
  }
  void subscribePrivate(String channelName, String event) {
    _channel.invokeMethod('subscribePrivate', {"channel": channelName, "event": event});
  }

  void trigger(String channelName, String event, String data){
    _channel.invokeMethod('trigger', {"channel": channelName, "event": event, "data": data});
  }

  Stream<PusherMessage> get onMessage => _messageChannel.receiveBroadcastStream().map(_toPusherMessage);

  PusherMessage _toPusherMessage(dynamic map) {
    if (map is Map) {
      var body = new Map<String, dynamic>.from(map['body']);
      return new PusherMessage(map['channel'], map['event'], body);
    }
    return null;
  }
}

class PusherMessage {
  final String channelName;
  final String eventName;
  final Map<String, dynamic> body;

  PusherMessage(this.channelName, this.eventName, this.body);
}
