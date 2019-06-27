import 'package:pusher/authorizer.dart' as PusherAuthorizer;
import 'package:http/http.dart' as http;

class Authorizer implements PusherAuthorizer.PusherAuthorizer{
  final String _url;

  Authorizer(this._url);


  @override
  Future<String> authorize(String channelName, String socketId) async {
    var response = await http.post(_url, body: {'channelName': channelName, socketId: socketId});
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    return null;
  }
}