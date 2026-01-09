class LocalAssetServer {
  int get port => 0;

  Future<void> start({String path = 'assets', int port = 0}) async {
    print('LocalAssetServer: Bypassing on Web (Stub).');
  }

  Future<void> stop() async {
    print('LocalAssetServer: Stop called on Web (Stub).');
  }
}
