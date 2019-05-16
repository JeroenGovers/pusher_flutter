import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pusher/pusher.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _lastError;
  PusherConnectionState _connectionState;
  Map _latestMessage;
  Pusher pusher = new Pusher('myKey',
      host: '192.168.123.244',
      encrypted: false,
      port: 6001,
      authorizer: 'http://192.168.123.244:8000/api/authorize');

  @override
  void initState() {
    super.initState();

    pusher.onConnectivityChanged.listen((state) {
      setState(() {
        _connectionState = state;
        if (state == PusherConnectionState.connected) {
          _lastError = null;
        }
      });
    });
    pusher.connect();

    pusher.subscribePrivate("private-sprinklers", "get");
    pusher.subscribe("sprinklers", "get");

    pusher.onMessage.listen((pusherMessage) {
      print(pusherMessage.body);
      setState(() => _latestMessage = pusherMessage.body);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pusher example app'),
        ),
        body: Center(
            child: Column(
          children: <Widget>[
            Text('Running'),
            Text("connection $_connectionState"),
            Text("error $_lastError"),
            Text("message $_latestMessage"),
            MaterialButton(
              child: Text("Send data"),
              onPressed: () {
                pusher.trigger('private-sprinklers', 'client-updateSprinkler', '{"id":1,"name":"Sproeiers3","status":true}');
              },
            ),
          ],
        )),
      ),
    );
  }
}
