part of upnp;

class StateSubscriptionManager {
  HttpServer server;
  Map<String, StateSubscription> _subs = {};
  Logger debugLogger;

  init() async {
    await close();

    server = await HttpServer.bind("0.0.0.0", 0);

    server.listen((HttpRequest request) {
      if (debugLogger != null) {
        debugLogger.fine("[Subscription Server] ${request.method} ${request.uri.path} by ${request.connectionInfo.remoteAddress.address}");
      }

      String id = request.uri.path.substring(1);

      if (_subs.containsKey(id)) {
        _subs[id].deliver(request);
      } else if (request.uri.path == "/_list") {
        request.response
          ..writeln(_subs.keys.join("\n"))
          ..close();
      } else if (request.uri.path == "/_state") {
        var out = "";
        for (String sid in _subs.keys) {
          out += "${sid}: ${_subs[sid]._lastValues}\n";
        }
        request.response
          ..write(out)
          ..close();
      } else {
        request.response.statusCode = HttpStatus.NOT_FOUND;
        request.response.close();
      }
    }, onError: (e) {});
  }

  close() async {
    for (String key in _subs.keys.toList()) {
      _subs[key]._done();
      _subs.remove(key);
    }

    if (server != null) {
      server.close(force: true);
      server = null;
    }
  }

  Stream<dynamic> subscribeToVariable(StateVariable v) {
    var id = v.getGenericId();
    StateSubscription sub;
    if (_subs.containsKey(id)) {
      sub = _subs[id];
    } else {
      sub = _subs[id] = new StateSubscription();
      sub.eventUrl = v.service.eventSubUrl;
      sub.lastStateVariable = v;
      sub.manager = this;
      sub.init();
    }

    return sub._controller.stream;
  }

  Stream<dynamic> subscribeToService(Service service) {
    var id = sha256.convert(UTF8.encode(service.eventSubUrl)).toString();
    StateSubscription sub = _subs[id];
    if (sub == null) {
      sub = _subs[id] = new StateSubscription();
      sub.eventUrl = service.eventSubUrl;
      sub.manager = this;
      sub.init();
    }
    return sub._controller.stream;
  }
}

class InternalNetworkUtils {
  static Future<String> getMostLikelyHost(Uri uri) async {
    var parts = uri.host.split(".");
    var interfaces = await NetworkInterface.list();

    String calc(int skip) {
      var prefix = parts.take(parts.length - skip).join(".") + ".";

      for (NetworkInterface interface in interfaces) {
        for (InternetAddress addr in interface.addresses) {
          if (addr.address.startsWith(prefix)) {
            return addr.address;
          }
        }
      }

      return null;
    }

    for (var i = 1; i <= 3; i++) {
      var ip = calc(i);
      if (ip != null) {
        return ip;
      }
    }

    return Platform.localHostname;
  }
}

class StateSubscription {
  static int REFRESH = 30;

  StateSubscriptionManager manager;
  StateVariable lastStateVariable;
  String eventUrl;
  StreamController<dynamic> _controller;
  Timer _timer;
  String lastCallbackUrl;

  String _lastSid;

  Map<String, dynamic> _lastValues;

  void init() {
    _controller = new StreamController<dynamic>.broadcast(
      onListen: () async {
        try {
          await _sub();
        } catch (e, stack) {
          _controller.addError(e, stack);
        }
      },
      onCancel: () => _unsub()
    );
  }

  deliver(HttpRequest request) async {
    var content = UTF8.decode(await request.fold(<int>[], (List<int> a, List<int> b) {
      return a..addAll(b);
    }));
    request.response.close();

    var doc = xml.parse(content);
    var props = doc.rootElement.children.where((x) => x is XmlElement).toList();
    var map = {};
    for (XmlElement prop in props) {
      if (prop.children.isEmpty) {
        continue;
      }

      XmlElement child = prop.children.firstWhere((x) => x is XmlElement);
      String p = child.name.local;

      if (lastStateVariable != null && lastStateVariable.name == p) {
        _controller.add(XmlUtils.asRichValue(child.text));
        return;
      } else if (lastStateVariable == null) {
        map[p] = XmlUtils.asRichValue(child.text);
      }
    }

    if (lastStateVariable == null && map.isNotEmpty) {
      _controller.add(map);
      _lastValues = map;
    }
  }

  String _getId() {
    if (lastStateVariable != null) {
      return lastStateVariable.getGenericId();
    } else {
      return sha256.convert(UTF8.encode(eventUrl)).toString();
    }
  }

  Future _sub() async {
    var id = _getId();

    var uri = Uri.parse(
      eventUrl
    );

    var request = new http.Request("SUBSCRIBE", uri);

    var url = await _getCallbackUrl(uri, id);
    lastCallbackUrl = url;

    request.headers.addAll({
      "User-Agent": "UPNP.dart/1.0",
      "ACCEPT": "*/*",
      "CALLBACK": "<${url}>",
      "NT": "upnp:event",
      "TIMEOUT": "Second-${REFRESH}",
      "HOST": "${request.url.host}:${request.url.port}"
    });

    var response = await UpnpCommon.httpClient.send(request);
    response.stream.drain();

    if (response.statusCode != HttpStatus.OK) {
      throw new Exception("Failed to subscribe.");
    }

    _lastSid = response.headers["sid"];

    _timer = new Timer(new Duration(seconds: REFRESH), () {
      _timer = null;
      _refresh();
    });
  }

  Future _refresh() async {
    var uri = Uri.parse(
      eventUrl
    );

    var id = _getId();
    var url = await _getCallbackUrl(uri, id);
    if (url != lastCallbackUrl) {
      await _unsub().timeout(const Duration(seconds: 10), onTimeout: () {
        return null;
      });
      await _sub();
      return;
    }

    var request = new http.Request("SUBSCRIBE", uri);

    request.headers.addAll({
      "User-Agent": "UPNP.dart/1.0",
      "ACCEPT": "*/*",
      "TIMEOUT": "Second-${REFRESH}",
      "SID": _lastSid,
      "HOST": "${request.url.host}:${request.url.port}"
    });

    var response = await UpnpCommon.httpClient.send(request)
      .timeout(const Duration(seconds: 10), onTimeout: () {
      return null;
    });

    if (response != null) {
      if (response.statusCode != HttpStatus.OK) {
        _controller.close();
        return;
      } else {
        _timer = new Timer(new Duration(seconds: REFRESH), () {
          _timer = null;
          _refresh();
        });
      }
    }
  }

  Future<String> _getCallbackUrl(Uri uri, String id) async {
    var host = await InternalNetworkUtils.getMostLikelyHost(uri);
    return "http://${host}:${manager.server.port}/${id}";
  }

  Future _unsub([bool close = false]) async {
    var request = new http.Request("UNSUBSCRIBE", Uri.parse(
      eventUrl
    ));

    request.headers.addAll({
      "User-Agent": "UPNP.dart/1.0",
      "ACCEPT": "*/*",
      "SID": _lastSid
    });

    var response = await UpnpCommon.httpClient.send(request)
      .timeout(const Duration(seconds: 10), onTimeout: () {
      return null;
    });

    if (response != null) {
      response.stream.drain();
    }

    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  void _done() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }

    if (_controller != null) {
      _controller.close();
    }
  }
}
