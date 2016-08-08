part of upnp.dial;

class DialScreen {
  final Uri baseUri;

  DialScreen(this.baseUri);

  factory DialScreen.forCastDevice(String ip) {
    return new DialScreen(Uri.parse("http://${ip}:8008/"));
  }

  Future<bool> isIdle() async {
    http.StreamedResponse response;
    try {
      response = await send("GET", "/apps");
      if (response.statusCode == 302) {
        return false;
      }
      return true;
    } finally {
      if (response != null) {
        response.stream.drain();
      }
    }
  }

  Future<http.StreamedResponse> send(String method, String path, {body, Map<String, dynamic> headers}) async {
    var request = new http.Request(method, baseUri.resolve(path));
    if (body is String) {
      request.body = body;
    } else if (body is List<int>) {
      request.bodyBytes = body;
    }

    if (headers != null) {
      request.headers.addAll(headers);
    }

    return await UpnpCommon.httpClient.send(request);
  }
}
