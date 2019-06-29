import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pusher/authorizer.dart';
import 'package:pusher/pusher.dart';
import 'authorizer.dart';
import 'change_notifiers/pusher_state.dart';
import 'change_notifiers/log.dart';
import 'datetime.dart';
import 'global_values/pusher.dart' as globals;
import 'global_values/connection.dart' as connection_values;
import 'initial_values/connection.dart' as connection_initials;

class Connection extends StatefulWidget {
  Connection({Key key}) : super(key: key);

  @override
  _Connection createState() => _Connection();
}

class _Connection extends State<Connection> {
  bool _encrypted = connection_values.encrypted ?? connection_initials.encrypted ?? true;

  initialValue(val) {
    return TextEditingController(text: val);
  }

  void connect() {
    final state = Provider.of<PusherStateNotifier>(context);
    final log = Provider.of<LogNotifier>(context);

    PusherAuthorizer pusherAuthorizer = new Authorizer(connection_values.authorizer ?? connection_initials.authorizer);

    globals.pusher = new Pusher(
      apiKey: connection_values.apiKey ?? connection_initials.apiKey,
      host: connection_values.host ?? connection_initials.host,
      cluster: connection_values.cluster ?? connection_initials.cluster,
      encrypted: connection_values.encrypted ?? connection_initials.encrypted,
      port: connection_values.port ?? connection_initials.port,
      activityTimeout: connection_values.activityTimeout ?? connection_initials.activityTimeout,
      pongTimeout: connection_values.pongTimeout ?? connection_initials.pongTimeout,
      maxReconnectionAttempts: connection_values.maxReconnectionAttempts ?? connection_initials.maxReconnectionAttempts,
      maxReconnectGapInSeconds: connection_values.maxReconnectGapInSeconds ?? connection_initials.maxReconnectGapInSeconds,
      authorizer: pusherAuthorizer,
      onConnectionStateChange: (Pusher pusher) {
        state.state = pusher.getState();
        log.add('state', pusher.getState().toString());
      },
      onConnectionError: (PusherError error) {
        print(error.message);
      },
    );
    globals.pusher.connect();
  }

  void disconnect() {
    globals.pusher.disconnect();
  }

  Widget button() {
    return Consumer<PusherStateNotifier>(builder: (context, state, _) {
      String text;
      Color color = Colors.amber;
      Function onPressed = disconnect;

      switch (state.state) {
        case PusherConnectionState.connecting:
          text = 'Connecting';

          break;
        case PusherConnectionState.disconnecting:
          text = 'Disconnecting';

          break;
        case PusherConnectionState.reconnecting:
          text = 'Reconnecting';

          break;
        case PusherConnectionState.reconnectingWhenNetworkBecomesReachable:
          text = 'Reconnecting (no netwerk)';

          break;
        case PusherConnectionState.connected:
          color = Colors.red;
          text = 'Disconnect';

          break;
        default:
          color = Colors.green;
          text = 'Connect';
          onPressed = connect;
      }

      return FlatButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: new RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        color: color,
        textColor: Colors.white,
        child: Text(text),
        onPressed: onPressed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return settings();
  }

  Widget settings() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(8.0),
            children: <Widget>[
              Card(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                child: ListTile(
                  title: Text('State'),
                  subtitle: Consumer<PusherStateNotifier>(
                    builder: (context, pusherState, _) {
                      return Text(pusherState.state.toString());
                    },
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.all(0),
                child: ListTile(
                  title: Text('SocketId'),
                  subtitle: Consumer<PusherStateNotifier>(
                    builder: (context, state, _) {
                      String socketId = '';
                      if (globals.pusher != null) {
                        socketId = globals.pusher.getSocketId();
                      }

                      if (socketId == '') {
                        socketId = '-';
                      }

                      return Text(socketId);
                    },
                  ),
                ),
              ),
              TextField(
                controller: initialValue(connection_values.apiKey ?? connection_initials.apiKey),
                decoration: InputDecoration(
                  labelText: 'apiKey *',
                ),
                onChanged: (String value) {
                  connection_values.apiKey = value;
                },
              ),
              TextField(
                controller: initialValue(connection_values.host ?? connection_initials.host),
                decoration: InputDecoration(
                  labelText: 'host',
                  helperText: 'default: ws.pusherapp.com',
                ),
                keyboardType: TextInputType.url,
                onChanged: (String value) {
                  connection_values.host = value;
                },
              ),
              TextField(
                controller: initialValue(connection_values.cluster ?? connection_initials.cluster),
                decoration: InputDecoration(labelText: 'cluster'),
                onChanged: (String value) {
                  connection_values.cluster = value;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: <Widget>[
                    Text('encrypted'),
                    Switch(
                      onChanged: (bool value) {
                        connection_values.encrypted = value;

                        setState(() {
                          _encrypted = value;
                        });
                      },
                      value: _encrypted,
                    ),
                  ],
                ),
              ),
              TextField(
                controller: initialValue(connection_values.port?.toString() ?? connection_initials.port?.toString()),
                decoration: InputDecoration(
                  labelText: 'port',
                  helperText: 'default: ' + (_encrypted ? '443' : '80'),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  WhitelistingTextInputFormatter.digitsOnly
                ],
                onChanged: (String value) {
                  connection_values.port = int.parse(value);
                },
              ),
              TextField(
                controller: initialValue(connection_values.activityTimeout?.toString() ?? connection_initials.activityTimeout?.toString()),
                decoration: InputDecoration(
                  labelText: 'activityTimeout',
                  helperText: 'milliseconds; default: 120000',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  WhitelistingTextInputFormatter.digitsOnly
                ],
                onChanged: (String value) {
                  connection_values.activityTimeout = int.parse(value);
                },
              ),
              TextField(
                controller: initialValue(connection_values.pongTimeout?.toString() ?? connection_initials.pongTimeout?.toString()),
                decoration: InputDecoration(
                  labelText: 'pongTimeout',
                  helperText: 'milliseconds; default: 30000',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  WhitelistingTextInputFormatter.digitsOnly
                ],
                onChanged: (String value) {
                  connection_values.pongTimeout = int.parse(value);
                },
              ),
              TextField(
                controller: initialValue(connection_values.maxReconnectionAttempts?.toString() ?? connection_initials.maxReconnectionAttempts?.toString()),
                decoration: InputDecoration(
                  labelText: 'maxReconnectionAttempts',
                  helperText: 'default: 6',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  WhitelistingTextInputFormatter.digitsOnly
                ],
                onChanged: (String value) {
                  connection_values.maxReconnectionAttempts = int.parse(value);
                },
              ),
              TextField(
                controller: initialValue(connection_values.maxReconnectGapInSeconds?.toString() ?? connection_initials.maxReconnectGapInSeconds?.toString()),
                decoration: InputDecoration(
                  labelText: 'maxReconnectGapInSeconds',
                  helperText: 'default: 30',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  WhitelistingTextInputFormatter.digitsOnly
                ],
                onChanged: (String value) {
                  connection_values.maxReconnectGapInSeconds = int.parse(value);
                },
              ),
              TextField(
                controller: initialValue(connection_values.authorizer ?? connection_initials.authorizer),
                decoration: InputDecoration(labelText: 'authorizer url (see authorizer.dart for more details)'),
                keyboardType: TextInputType.url,
                onChanged: (String value) {
                  connection_values.authorizer = value;
                },
              ),
            ],
          ),
        ),
        Container(
          child: SizedBox(
            width: double.infinity,
            child: button(),
          ),
        ),
      ],
    );
  }
}
