import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:pusher/channels/public.dart';
import 'package:pusher/pusher.dart';
import 'package:pusher_example/channel.dart';
import 'global_values/pusher.dart' as globals;

import 'change_notifiers/public_channel.dart';
import 'change_notifiers/log.dart';

class PublicChannelView extends StatefulWidget {
  PublicChannelView({Key key}) : super(key: key);

  @override
  _PublicChannel createState() => _PublicChannel();
}

class _PublicChannel extends State<PublicChannelView> with Channel {
  PublicChannelProvider _provider;

  @override
  Widget build(BuildContext context) {
    final log = Provider.of<LogNotifier>(context);
    _provider = Provider.of<PublicChannelProvider>(context);

    return Scaffold(
      body: Consumer<PublicChannelProvider>(
        builder: (context, PublicChannelProvider provider, _) {
          return channelListView(
            'publicChannel',
            provider,
            (String channelName) {
              PublicChannel channel = globals.pusher.getChannel(channelName);
              channel.unsubscribe();
              _provider.remove(channelName);
            },
            (String channelName, String event) {
              PublicChannel channel = globals.pusher.getChannel(channelName);
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
              return subscribeDialog(context, 'Public channel', (channel, event) {
                globals.pusher.subscribe(
                  channelName: channel,
                  event: event,
                  onEvent: (PusherMessage message) {
                    log.add('event', channel +'.'+ event +': '+ message.body.toString());
                  },
                  onSubscriptionSucceeded: (PusherMessage message) {
                    log.add('event', channel +'.subscription-succeeded: '+ message.body.toString());
                  },
                  onStateChange: (PusherMessage message){
                    log.add('state', channel +'.state: '+ message.body.toString());
                  }
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
