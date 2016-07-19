part of upnp;

class StateSubscriptionManager {
  HttpServer server;
  Map<String, StateSubscription> _subs = {};

  init() async {
    await close();

    server = await HttpServer.bind("0.0.0.0", 0);

    server.listen((HttpRequest request) {
      String id = request.uri.path.substring(1);

      if (_subs.containsKey(id)) {
        _subs[id].deliver(request);
      }
    });
  }

  close() async {
    for (String key in _subs.keys.toList()) {
      _subs[key]._controller.close();
      _subs.remove(key);
    }

    if (server != null) {
      server.close(force: true);
      server = null;
    }
  }

  Stream<dynamic> subscribe(StateVariable v) {
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
}

class StateSubscription {
  StateSubscriptionManager manager;
  StateVariable lastStateVariable;
  String eventUrl;
  StreamController<dynamic> _controller;

  void init() {
    _controller = new StreamController<dynamic>.broadcast(
      onListen: () => _sub(),
      onCancel: () => _unsub()
    );
  }

  deliver(HttpRequest request) async {
    var content = UTF8.decode(await request.fold(<int>[], (List<int> a, List<int> b) {
      return a..addAll(b);
    }));

    print(content);

    request.response.close();
  }

  Future _sub() async {
    var id = lastStateVariable.getGenericId();

    var request = new http.Request("SUBSCRIBE", Uri.parse(
      eventUrl
    ));

    request.headers.addAll({
      "USER-AGENT": "UPNP.dart/1.0",
      "CALLBACK": "<http://${Platform.localHostname}:${manager.server.port}/${id}>",
      "NT": "upnp:event",
      "TIMEOUT": "31556926", // Thirty year subscription, because infinite is not a thing...
      "HOST": "${request.url.host}:${request.url.port}"
    });

    var response = await UpnpCommon.httpClient.send(request);
    var responseContent = await response.stream.bytesToString();
  }

  Future _unsub() async {
    var request = new http.Request("UNSUBSCRIBE", Uri.parse(
      eventUrl
    ));

    var id = lastStateVariable.getGenericId();
    request.headers.addAll({
      "USER-AGENT": "UPNP.dart/1.0",
      "CALLBACK": "<http://${Platform.localHostname}:${manager.server.port}/${id}>",
      "NT": "upnp:event",
      "TIMEOUT": "31556926"
    });

    var response = await UpnpCommon.httpClient.send(request);
    var responseContent = await response.stream.bytesToString();
  }
}
