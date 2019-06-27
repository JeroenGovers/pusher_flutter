import 'package:flutter/material.dart';
import 'package:pusher_example/change_notifiers/channel.dart' as changeNotifier;

class Channel {
  Widget channelListView(String title, changeNotifier.Channel provider, Function deleteChannel(String channelName), Function deleteEvent(String channelName, String event)) {
    if (provider.list.length == 0) {
      return Center(
        child: Text(title),
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
            deleteChannel(channelName);
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
                deleteEvent(channelName, event);
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
  }

  AlertDialog dialog(BuildContext context, String title, Function onSubscribe(String channelName, String event)) {
    String channel;
    String event;

    return AlertDialog(
      title: Text(title),
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
            onSubscribe(channel, event);

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
}
