import 'dart:convert';

import 'package:pusher/authorizer.dart' as PusherAuthorizer;
import 'package:http/http.dart' as http;

class Authorizer implements PusherAuthorizer.PusherAuthorizer{
  final String _url;

  Authorizer(this._url);


  @override
  Future<String> authorize(String channelName, String socketId) async {
    var response = await http.post(_url, body: {'channel_name': channelName, 'socket_id': socketId});
    if(response.statusCode == 200){
      return jsonDecode(response.body)['auth'];
    }

    return '';
  }
}