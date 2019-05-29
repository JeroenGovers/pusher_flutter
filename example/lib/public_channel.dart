import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PublicChannel extends StatefulWidget {
  PublicChannel({Key key}) : super(key: key);

  @override
  _PublicChannel createState() => _PublicChannel();
}

class _PublicChannel extends State<PublicChannel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('publicChannel'),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          print('add');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
