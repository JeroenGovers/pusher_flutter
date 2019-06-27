abstract class PusherAuthorizer {
  Future<String> authorize(String channelName, String socketId);
}
