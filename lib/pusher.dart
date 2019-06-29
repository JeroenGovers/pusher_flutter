import 'package:flutter/foundation.dart';
import 'authorizer.dart';
import 'src/channel_manager.dart';
import 'channels/public.dart';
import 'channels/presence.dart';
import 'channels/private.dart';
import 'event_handlers/connection_error.dart';
import 'event_handlers/connection_state_change.dart';

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

  ChannelManager _channelManager;

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
    PusherAuthorizer authorizer,
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
    String url = 'ws';
    if (encrypted) {
      url += 'wss';
    }
    url += '://' + host;
    url += ':' + port.toString();
    url += '/app/';
    url += apiKey;
    url += '?client=flutter&protocol=5&version=1';

    //TODO: implement this
    // args["activityTimeout"] = activityTimeout;
    // args["pongTimeout"] = pongTimeout;
    // args["maxReconnectionAttempts"] = maxReconnectionAttempts;
    // args["maxReconnectGapInSeconds"] = maxReconnectGapInSeconds;

    _channelManager = new ChannelManager(this, url, authorizer);

    if (onConnectionStateChange != null) {
      _channelManager.addEventHandler(
        'pusher:connection',
        'state',
        onConnectionStateChange,
        ConnectionStateChange(),
      );
    }

    if (onConnectionError != null) {
      _channelManager.addEventHandler(
        'pusher:connection',
        'error',
        onConnectionError,
        ConnectionError(),
      );
    }
  }

  void connect() {
    _channelManager.connect();
  }

  bool isConnected() {
    return getState() == PusherConnectionState.connected;
  }

  void disconnect() {
    _channelManager.disconnect();
  }

  String getSocketId() {
    return _channelManager.getSocketId();
  }

  PusherConnectionState getState() {
    return _channelManager.getState();
  }

  void _checkPublicChannelName(String channelName, String privateFunctionName, String presenceFunctionName){
    if (channelName.startsWith(PRIVATE_PREFIX)) {
      throw new Exception('Please use the '+ privateFunctionName +' method');
    } else if (channelName.startsWith(PRESENCE_PREFIX)) {
      throw new Exception('Please use the '+ presenceFunctionName +' method');
    }
  }
  void _checkPrivateChannelName(String channelName, String publicFunctionName, String presenceFunctionName){
    if (!channelName.startsWith(PRIVATE_PREFIX)) {
      if (channelName.startsWith(PRESENCE_PREFIX)) {
        throw new Exception('Please use the '+ presenceFunctionName +' method');
      } else {
        throw new Exception('Please use the '+ publicFunctionName +' method');
      }
    }
  }
  void _checkPresenceChannelName(String channelName, String publicFunctionName, String privateFunctionName){
    if (!channelName.startsWith(PRESENCE_PREFIX)) {
      if (channelName.startsWith(PRIVATE_PREFIX)) {
        throw new Exception('Please use the '+ privateFunctionName +' method');
      } else {
        throw new Exception('Please use the '+ publicFunctionName +' method');
      }
    }
  }

  PublicChannel subscribe({
    @required String channelName,
    @required dynamic event,
    @required Function(PusherMessage) onEvent,
    Function(PusherMessage) onStateChange,
    Function(PusherMessage) onSubscriptionSucceeded,
  }) {
    _checkPublicChannelName(channelName, 'subscribePrivate', 'subscribePresence');

    return _channelManager.subscribe(channelName, event, onEvent, onStateChange, onSubscriptionSucceeded);
  }

  PrivateChannel subscribePrivate({
    @required String channelName,
    @required dynamic event,
    @required Function(PusherMessage) onEvent,
    Function(PusherMessage) onStateChange,
    Function(PusherMessage) onSubscriptionSucceeded,
    Function(PusherMessage) onAuthenticationFailure,
  }) {
    _checkPrivateChannelName(channelName, 'subscribe', 'subscribePresence');

    return _channelManager.subscribe(channelName, event, onEvent, onStateChange, onSubscriptionSucceeded, onAuthenticationFailure: onAuthenticationFailure);
  }

  PresenceChannel subscribePresence({
    @required String channelName,
    @required dynamic event,
    @required Function(PusherMessage) onEvent,
    Function(PusherMessage) onStateChange,
    Function(PusherMessage) onSubscriptionSucceeded,
    Function(PusherMessage) onAuthenticationFailure,
  }) {
    _checkPresenceChannelName(channelName, 'subscribe', 'subscribePrivate');

    return _channelManager.subscribe(channelName, event, onEvent, onStateChange, onSubscriptionSucceeded, onAuthenticationFailure: onAuthenticationFailure);
  }

  PublicChannel getChannel(String channelName) {
    _checkPublicChannelName(channelName, 'getPrivateChannel', 'getPresenceChannel');

    return _channelManager.getChannel(channelName);
  }

  PrivateChannel getPrivateChannel(String channelName) {
    _checkPrivateChannelName(channelName, 'getChannel', 'getPresenceChannel');

    return _channelManager.getChannel(channelName);
  }

  PresenceChannel getPresenceChannel(String channelName) {
    _checkPresenceChannelName(channelName, 'getChannel', 'getPrivateChannel');

    return _channelManager.getChannel(channelName);
  }

  void unsubscribe(String channelName) {
    _channelManager.unsubscribe(channelName);
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
