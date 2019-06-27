import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:pusher/channels/private.dart';
import 'package:pusher/pusher.dart';
import 'package:pusher_example/channel.dart';
import 'change_notifiers/private_channel.dart';
import 'global_values/pusher.dart' as globals;

class PrivateChannelView extends StatefulWidget {
  PrivateChannelView({Key key}) : super(key: key);

  @override
  _PrivateChannel createState() => _PrivateChannel();
}

class _PrivateChannel extends State<PrivateChannelView> with Channel {
  PrivateChannelProvider _provider;

  @override
  Widget build(BuildContext context) {
    _provider = Provider.of<PrivateChannelProvider>(context);

    return Scaffold(
      body: Consumer<PrivateChannelProvider>(
        builder: (context, PrivateChannelProvider provider, _) {
          return channelListView(
            'privateChannel',
            provider,
            (String channelName) {
              PrivateChannel channel = globals.pusher.getPrivateChannel(channelName);
              channel.unsubscribe();
              _provider.remove(channelName);
            },
            (String channelName, String event) {
              PrivateChannel channel = globals.pusher.getPrivateChannel(channelName);
              channel.removeEventHandler(event);
              _provider.remove(channelName, event: event);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return dialog(context, 'Private channel', (channel, event) {
                globals.pusher.subscribePrivate(
                  channelName: channel,
                  event: event,
                  onEvent: (PusherMessage message) {
                    print('event:' + message.body.toString());
                  },
                  onSubscriptionSucceeded: (PusherMessage message) {
                    print('subscription-succeeded:' + message.body.toString());
                  },
                );
                _provider.add(channel, event);
              });
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
