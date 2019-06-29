import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher/pusher.dart';
import 'package:pusher_example/public_channel.dart';

import 'change_notifiers/private_channel.dart';
import 'change_notifiers/public_channel.dart';
import 'change_notifiers/pusher_state.dart';
import 'change_notifiers/log.dart';
import 'connection.dart';
import 'log.dart';
import 'private_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  static const String _title = 'Pusher Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: MyAppWidget(),
    );
  }
}

class MyAppWidget extends StatefulWidget {
  MyAppWidget({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyAppWidget> {
  int _selectedIndex = 0;
  String _latestMessage;
  String _lastError;

  @override
  void initState() {
    super.initState();

    // _pusher = new Pusher(
    //   apiKey: 'myKey',
    //   host: '192.168.123.244',
    //   encrypted: false,
    //   port: 6001,
    //   authorizer: 'http://192.168.123.244:8000/api/authorize',
    //   onConnectionStateChange: (Pusher pusher) {
    //     setState(() {
    //       _connectionState = pusher.getState();

    //       if (_connectionState == PusherConnectionState.connected) {
    //         _lastError = null;
    //       }
    //     });
    //   },
    // );
    // _pusher.connect();

    // _pusher.subscribe(
    //   channelName: "sprinklers",
    //   event: "get",
    //   onEvent: (PusherMessage message) {
    //     print(message);
    //   },
    //   onSubscriptionSucceeded: (PusherMessage message) {
    //     print(message);
    //   },
    // );

    // _pusher.subscribePrivate(
    //   channelName: "private-sprinklers",
    //   event: "get",
    //   onEvent: (PusherMessage message) {
    //     setState(() {
    //       _latestMessage = message.body;
    //     });
    //   },
    //   onSubscriptionSucceeded: (PusherMessage message) {
    //     print(message);
    //   },
    // );
    // pusher.subscribePresence("private-sprinklers", "get");
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (context) => PusherStateNotifier()),
        ChangeNotifierProvider(builder: (context) => LogNotifier()),
        ChangeNotifierProvider(builder: (context) => PublicChannelProvider()),
        ChangeNotifierProvider(builder: (context) => PrivateChannelProvider()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pusher example app'),
        ),
        body: Center(
          child: Flex(
            direction: Axis.vertical,
            children: <Widget>[
              Visibility(
                visible: _selectedIndex == 0,
                child: Expanded(
                  child: Connection(),
                ),
              ),
              Visibility(
                visible: _selectedIndex == 1,
                child: Expanded(
                  child: PublicChannelView(),
                ),
              ),
              Visibility(
                visible: _selectedIndex == 2,
                child: Expanded(
                  child: PrivateChannelView(),
                ),
              ),
              Visibility(
                visible: _selectedIndex == 3,
                child: Text("message $_latestMessage"),
              ),
              Visibility(
                visible: _selectedIndex == 4,
                child: Expanded(
                  child: Log(),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Consumer<PusherStateNotifier>(
          builder: (context, state, _) {
            bool active = false;
            IconData connectionIcon = Icons.signal_cellular_off;
            Color buttonColor = Colors.grey[200];

            switch (state.state) {
              case PusherConnectionState.connecting:
              case PusherConnectionState.reconnecting:
              case PusherConnectionState.disconnecting:
              case PusherConnectionState.reconnectingWhenNetworkBecomesReachable:
                connectionIcon = Icons.signal_cellular_null;

                break;
              case PusherConnectionState.reconnectingWhenNetworkBecomesReachable:
                connectionIcon = Icons.signal_cellular_connected_no_internet_4_bar;

                break;
              case PusherConnectionState.connected:
                connectionIcon = Icons.signal_cellular_4_bar;
                buttonColor = null;
                active = true;

                break;
              default:
            }

            return BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: IconIndicator(
                    connectionIcon,
                  ),
                  title: Text('Connection'),
                ),
                BottomNavigationBarItem(
                  icon: IconIndicator(
                    Icons.sms,
                    number: 0,
                    disabled: !active,
                  ),
                  title: Text(
                    'Public',
                    style: TextStyle(
                      color: buttonColor,
                    ),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: IconIndicator(
                    Icons.sms_failed,
                    number: 0,
                    disabled: !active,
                  ),
                  title: Text(
                    'Private',
                    style: TextStyle(
                      color: buttonColor,
                    ),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: IconIndicator(
                    Icons.view_list,
                    number: 0,
                    disabled: !active,
                  ),
                  title: Text(
                    'Presence',
                    style: TextStyle(
                      color: buttonColor,
                    ),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: Consumer<LogNotifier>(
                    builder: (BuildContext context, LogNotifier log, Widget child) {
                      return IconIndicator(
                        Icons.format_align_left,
                        number: log.newLength,
                      );
                    },
                  ),
                  title: Text(
                    'Log',
                  ),
                ),
              ],
              currentIndex: _selectedIndex,
              unselectedItemColor: Colors.grey,
              selectedItemColor: Colors.amber[800],
              type: BottomNavigationBarType.fixed,
              onTap: (int index) {
                if (index == 0 || index == 4 || active) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class IconIndicator extends StatelessWidget {
  const IconIndicator(
    this.icon, {
    this.number,
    this.error,
    this.disabled,
  });

  final IconData icon;
  final int number;
  final bool error;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color bullColor = Colors.blue;
    if (error == true) {
      bullColor = Colors.red;
    }
    if (disabled == true) {
      iconColor = Colors.grey[200];
    }

    return Stack(
      overflow: Overflow.visible,
      children: <Widget>[
        Icon(
          icon,
          color: iconColor,
        ),
        Visibility(
          visible: (number != null && number > 0),
          child: Positioned(
            top: -4,
            right: -8,
            child: Container(
              width: 14,
              height: 14,
              decoration: new BoxDecoration(
                color: bullColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
