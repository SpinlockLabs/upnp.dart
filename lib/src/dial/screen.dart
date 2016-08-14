part of upnp.dial;

class DialScreen {
  static Stream<DialScreen> find() async* {
    var discovery = new DeviceDiscoverer();
    var ids = new Set<String>();

    await for (DiscoveredClient client in discovery.quickDiscoverClients(
      timeout: const Duration(seconds: 5),
      query: "urn:dial-multiscreen-org:device:dial:1"
    )) {
      if (ids.contains(client.usn)) {
        continue;
      }
      ids.add(client.usn);

      try {
        var dev = await client.getDevice();
        yield new DialScreen(
          Uri.parse(Uri.parse(client.location).origin),
          dev.friendlyName
        );
      } catch (e) {
      }
    }
  }

  final Uri baseUri;
  final String name;

  DialScreen(this.baseUri, this.name);

  factory DialScreen.forCastDevice(String ip, String deviceName) {
    return new DialScreen(Uri.parse("http://${ip}:8008/"), deviceName);
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

  Future launch(String app, {payload}) async {
    if (payload is Map) {
      var out = "";
      for (String key in payload.keys) {
        if (out.isNotEmpty) {
          out += "&";
        }

        out += "${Uri.encodeComponent(key)}=${Uri.encodeComponent(payload[key].toString())}";
      }
      payload = out;
    }

    http.StreamedResponse response;
    try {
      response = await send("POST", "/apps/${app}", body: payload);
      if (response.statusCode == 201) {
        return true;
      }
      return false;
    } finally {
      if (response != null) {
        response.stream.drain();
      }
    }
  }

  Future<bool> hasApp(String app) async {
    http.StreamedResponse response;
    try {
      response = await send("GET", "/apps/${app}");
      if (response.statusCode == 404) {
        return false;
      }
      return true;
    } finally {
      if (response != null) {
        response.stream.drain();
      }
    }
  }

  Future<String> getCurrentApp() async {
    http.StreamedResponse response;
    try {
      response = await send("GET", "/apps");
      if (response.statusCode == 302) {
        var loc = response.headers["location"];
        var uri = Uri.parse(loc);
        return uri.pathSegments[1];
      }
      return null;
    } finally {
      if (response != null) {
        response.stream.drain();
      }
    }
  }

  Future<bool> close([String app]) async {
    var toClose = app == null ? await getCurrentApp() : app;
    if (toClose != null) {
      http.StreamedResponse response;
      try {
        response = await send("DELETE", "/apps/${toClose}");
        if (response.statusCode != 200) {
          return false;
        }
        return true;
      } finally {
        if (response != null) {
          response.stream.drain();
        }
      }
    }
    return false;
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
