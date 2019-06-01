import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'change_notifiers/public_channel.dart';

class PublicChannel extends StatefulWidget {
  PublicChannel({Key key}) : super(key: key);

  @override
  _PublicChannel createState() => _PublicChannel();
}

class _PublicChannel extends State<PublicChannel> {
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
            list.add(Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(channelName),
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
                      _provider.remove(channelName, event);
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
