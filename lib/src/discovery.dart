part of upnp;

final InternetAddress _v4_Multicast = new InternetAddress("239.255.255.250");
final InternetAddress _v6_Multicast = new InternetAddress("FF05::C");

class DeviceDiscoverer {
  List<RawDatagramSocket> _sockets = <RawDatagramSocket>[];
  StreamController<DiscoveredClient> _clientController =
    new StreamController.broadcast();

  late List<NetworkInterface> _interfaces;

  Future start({bool ipv4: true, bool ipv6: true}) async {
    _interfaces = await NetworkInterface.list();

    if (ipv4) {
      await _createSocket(InternetAddress.anyIPv4);
    }

    if (ipv6) {
      await _createSocket(InternetAddress.anyIPv6);
    }
  }

  _createSocket(InternetAddress address) async {
    var socket = await RawDatagramSocket.bind(address, 0);

    socket.broadcastEnabled = true;
    socket.readEventsEnabled = true;
    socket.multicastHops = 50;

    socket.listen((event) {
      switch (event) {
        case RawSocketEvent.read:
          var packet = socket.receive();
          socket.writeEventsEnabled = true;
          socket.readEventsEnabled = true;

          if (packet == null) {
            return;
          }

          var data = utf8.decode(packet.data);
          var parts = data.split("\r\n");
          parts.removeWhere((x) => x.trim().isEmpty);
          var firstLine = parts.removeAt(0);

          if (
            (firstLine.toLowerCase().trim() == "HTTP/1.1 200 OK".toLowerCase()) ||
            (firstLine.toLowerCase().trim() == "NOTIFY * HTTP/1.1".toLowerCase())) {
            var headers = <String, String>{};
            var client = new DiscoveredClient();

            for (var part in parts) {
              var hp = part.split(":");
              var name = hp[0].trim();
              var value = (hp..removeAt(0)).join(":").trim();
              headers[name.toUpperCase()] = value;
            }

            if (!headers.containsKey("LOCATION")) {
              return;
            }

            client.st = headers["ST"];
            client.usn = headers["USN"];
            client.location = headers["LOCATION"];
            client.server = headers["SERVER"];
            client.headers = headers;

            _clientController.add(client);
          }

          break;
        case RawSocketEvent.write:
          break;
      }
    });

    try {
      socket.joinMulticast(_v4_Multicast);
    } on OSError {
    }

    try {
      socket.joinMulticast(_v6_Multicast);
    } on OSError {
    }

    for (var interface in _interfaces) {
      try {
        socket.joinMulticast(_v4_Multicast, interface);
      } on OSError {
      }

      try {
        socket.joinMulticast(_v6_Multicast, interface);
      } on OSError {
      }
    }

    _sockets.add(socket);
  }

  void stop() {
    if (_discoverySearchTimer != null) {
      _discoverySearchTimer!.cancel();
      _discoverySearchTimer = null;
    }

    for (var socket in _sockets) {
      socket.close();
    }

    if (!_clientController.isClosed) {
      _clientController.close();
      _clientController = new StreamController<DiscoveredClient>.broadcast();
    }
  }

  Stream<DiscoveredClient> get clients => _clientController.stream;

  void search([String? searchTarget]) {
    if (searchTarget == null) {
      searchTarget = "upnp:rootdevice";
    }

    var buff = new StringBuffer();

    buff.write("M-SEARCH * HTTP/1.1\r\n");
    buff.write("HOST: 239.255.255.250:1900\r\n");
    buff.write('MAN: "ssdp:discover"\r\n');
    buff.write("MX: 1\r\n");
    buff.write("ST: ${searchTarget}\r\n");
    buff.write("USER-AGENT: unix/5.1 UPnP/1.1 crash/1.0\r\n\r\n");
    var data = utf8.encode(buff.toString());

    for (var socket in _sockets) {
      if (socket.address.type == _v4_Multicast.type) {
        try {
          socket.send(data, _v4_Multicast, 1900);
        } on SocketException {
        }
      }

      if (socket.address.type == _v6_Multicast.type) {
        try {
          socket.send(data, _v6_Multicast, 1900);
        } on SocketException {
        }
      }
    }
  }

  Future<List<DiscoveredClient>> discoverClients({
    Duration timeout: const Duration(seconds: 5)
  }) async {
    var list = <DiscoveredClient>[];

    var sub = clients.listen((client) => list.add(client));

    if (_sockets.isEmpty) {
      await start();
    }

    search();
    await new Future.delayed(timeout);
    sub.cancel();
    stop();
    return list;
  }

  Timer? _discoverySearchTimer;

  Stream<DiscoveredClient> quickDiscoverClients({
    Duration timeout: const Duration(seconds: 5),
    Duration searchInterval: const Duration(seconds: 10),
    String? query,
    bool unique: true
  }) async* {
    if (_sockets.isEmpty) {
      await start();
    }

    var seen = new Set<String?>();

    if (timeout != null) {
      search(query);
      new Future.delayed(timeout, () {
        stop();
      });
    } else if (searchInterval != null) {
      search(query);
      _discoverySearchTimer = new Timer.periodic(searchInterval, (_) {
        search(query);
      });
    }

    await for (var client in clients) {
      if (unique && seen.contains(client.usn)) {
        continue;
      }

      seen.add(client.usn);
      yield client;
    }
  }

  Future<List<DiscoveredDevice>> discoverDevices({
    String? type,
    Duration timeout: const Duration(seconds: 5)
  }) {
    return discoverClients(timeout: timeout).then((clients) {
      if (clients.isEmpty) {
        return [];
      }

      var uuids = clients
        .where((client) => client.usn != null)
        .map((client) => client.usn!.split("::").first)
        .toSet();
      var devices = <DiscoveredDevice>[];

      for (var uuid in uuids) {
        var deviceClients = clients.where((client) {
          return client != null &&
            client.usn != null &&
            client.usn!.split("::").first == uuid;
        }).toList();
        var location = deviceClients.first.location;
        var serviceTypes = deviceClients
          .map((it) => it.st)
          .toSet()
          .toList();
        var device = new DiscoveredDevice();
        device.serviceTypes = serviceTypes;
        device.uuid = uuid;
        device.location = location;
        if (type == null || serviceTypes.contains(type)) {
          devices.add(device);
        }
      }

      for (var client in clients.where((it) => it.usn == null)) {
        var device = new DiscoveredDevice();
        device.serviceTypes = [client.st];
        device.uuid = null;
        device.location = client.location;
        if (type == null || device.serviceTypes.contains(type)) {
          devices.add(device);
        }
      }

      return devices;
    });
  }

  Future<List<Device>> getDevices({
    String? type,
    Duration timeout: const Duration(seconds: 5),
    bool silent: true
  }) async {
    var results = await discoverDevices(type: type, timeout: timeout);

    var list = <Device>[];
    for (var result in results) {
      try {
        var device = await result.getRealDevice();

        if (device == null) {
          continue;
        }
        list.add(device);
      } on ArgumentError {
      } catch (e) {
        if (!silent) {
          rethrow;
        }
      }
    }

    return list;
  }
}

class DiscoveredDevice {
  List<String?> serviceTypes = [];
  String? uuid;
  String? location;

  Future<Device?> getRealDevice() async {
    HttpClientResponse response;

    try {
      var request = await UpnpCommon.httpClient.getUrl(Uri.parse(location!)).timeout(
        const Duration(seconds: 5),
        onTimeout: (() => null) as FutureOr<HttpClientRequest> Function()?
      );

      response = await request.close();
    } catch (_) {
      return null;
    }

    if (response == null) {
      return null;
    }

    if (response.statusCode != 200) {
      throw new Exception(
        "ERROR: Failed to fetch device description."
          " Status Code: ${response.statusCode}"
      );
    }

    XmlDocument doc;

    try {
      var content = await response.cast<List<int>>().transform(utf8.decoder).join();
      doc = xml.parse(content);
    } on Exception catch (e) {
      throw new FormatException(
        "ERROR: Failed to parse"
          " device description. ${e}"
      );
    }

    if (doc.findAllElements("device").isEmpty) {
      throw new ArgumentError("Not SCPD Compatible");
    }

    return new Device()..loadFromXml(location, doc.rootElement);
  }
}

class DiscoveredClient {
  String? st;
  String? usn;
  String? server;
  String? location;
  Map<String, String>? headers;

  DiscoveredClient();

  DiscoveredClient.fake(String loc) {
    location = loc;
  }

  String toString() {
    var buff = new StringBuffer();
    buff.writeln("ST: ${st}");
    buff.writeln("USN: ${usn}");
    buff.writeln("SERVER: ${server}");
    buff.writeln("LOCATION: ${location}");
    return buff.toString();
  }

  Future<Device?> getDevice() async {
    Uri uri;

    try {
      uri = Uri.parse(location!);
    } catch (e) {
      return null;
    }

    var request = await UpnpCommon.httpClient
      .getUrl(uri)
      .timeout(const Duration(seconds: 10));

    var response = await request.close();

    if (response.statusCode != 200) {
      throw new Exception(
        "ERROR: Failed to fetch device description."
          " Status Code: ${response.statusCode}"
      );
    }

    XmlDocument doc;

    try {
      var content = await response.cast<List<int>>().transform(utf8.decoder).join();
      doc = xml.parse(content);
    } on Exception catch (e) {
      throw new FormatException(
        "ERROR: Failed to parse device"
          " description. ${e}");
    }

    return new Device()..loadFromXml(location, doc.rootElement);
  }
}
