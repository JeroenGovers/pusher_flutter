import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:pusher/channels/public.dart';
import 'package:pusher/pusher.dart';
import 'global_values/pusher.dart' as globals;

import 'change_notifiers/public_channel.dart';

class PublicChannelView extends StatefulWidget {
  PublicChannelView({Key key}) : super(key: key);

  @override
  _PublicChannel createState() => _PublicChannel();
}

class _PublicChannel extends State<PublicChannelView> {
  PublicChannelProvider _provider;

  AlertDialog dialog(BuildContext context) {
    String channel;
    String event;

    return AlertDialog(
      title: Text('Public channel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            decoration: InputDecoration(
              labelText: 'Channel *',
            ),
            onChanged: (value) {
              channel = value;
            },
          ),
          TextField(
            decoration: InputDecoration(
              labelText: 'Event *',
            ),
            onChanged: (value) {
              event = value;
            },
          ),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Subscribe'),
          onPressed: () {
            globals.pusher.subscribe(
              channelName: channel,
              event: event,
              onEvent: (PusherMessage message) {
                print('event:'+ message.body.toString());
              },
              onSubscriptionSucceeded: (PusherMessage message) {
                print('subscription-succeeded:'+ message.body.toString());
              },
            );
            _provider.add(channel, event);

            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _provider = Provider.of<PublicChannelProvider>(context);

    return Scaffold(
      body: Consumer<PublicChannelProvider>(
        builder: (context, PublicChannelProvider provider, _) {
          if (provider.list.length == 0) {
            return Center(
              child: Text('publicChannel'),
            );
          }

          List list = <Widget>[];
          Map<String, Map<String, List>> channelMap = provider.list;
          List<String> channelKeys = channelMap.keys.toList()..sort();
          channelKeys.forEach((String channelName) {
            list.add(ListTile(
                title: Text(channelName),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    PublicChannel channel = globals.pusher.getChannel(channelName);
                    channel.unsubscribe();
                    _provider.remove(channelName);
                  },
                ),
              ));

            Map<String, List> eventMap = channelMap[channelName];
            List<String> eventKeys = eventMap.keys.toList()..sort();

            eventKeys.forEach((String event) {
              list.add(Card(
                child: ListTile(
                  title: Text(event),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      PublicChannel channel = globals.pusher.getChannel(channelName);
                      channel.removeEventHandler(event);
                      _provider.remove(channelName, event: event);
                    },
                  ),
                ),
              ));
            });
          });

          return ListView(
            padding: EdgeInsets.all(8.0),
            children: list,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return dialog(context);
              });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
