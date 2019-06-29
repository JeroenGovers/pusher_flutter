import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'change_notifiers/log.dart';
import 'datetime.dart';

class Log extends StatefulWidget {
  Log({Key key}) : super(key: key);

  @override
  _Log createState() => _Log();
}

class _Log extends State<Log>{
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 8,
              ),
              child: Consumer<LogNotifier>(
                builder: (context, LogNotifier log, _) {
                  List<Widget> list = [];

                  log.list.forEach((message) {
                    list.add(Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.message,
                          size: 24,
                        ),
                        title: Text(message['message']),
                        subtitle: DateTimeFormatter(message['datetime']),
                        dense: true,
                      ),
                    ));
                  });

                  return ListView(
                    children: list,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
