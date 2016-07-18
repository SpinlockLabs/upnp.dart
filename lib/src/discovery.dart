part of upnp;

final InternetAddress _v4_Multicast = new InternetAddress("239.255.255.250");
final InternetAddress _v6_Multicast = new InternetAddress("FF05::C");

class DeviceDiscoverer {
  RawDatagramSocket _socket;
  StreamController<DiscoveredClient> _clientController =
    new StreamController.broadcast();

  List<NetworkInterface> _interfaces;

  Future start() async {
    _socket = await RawDatagramSocket.bind("0.0.0.0", 0);

    _socket.broadcastEnabled = true;
    _socket.multicastHops = 20;

    _socket.listen((event) {
      switch (event) {
        case RawSocketEvent.READ:
          var packet = _socket.receive();
          _socket.writeEventsEnabled = true;

          if (packet == null) {
            return;
          }

          var data = UTF8.decode(packet.data);
          var parts = data.split("\r\n");
          parts.removeWhere((x) => x.trim().isEmpty);
          var firstLine = parts.removeAt(0);

          if (firstLine.toLowerCase().trim() ==
            "HTTP/1.1 200 OK".toLowerCase()) {
            var headers = {};
            var client =  new DiscoveredClient();

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
        case RawSocketEvent.WRITE:
          break;
      }
    });

    _interfaces = await NetworkInterface.list();
    var joinMulticastFunction = _socket.joinMulticast;
    for (var interface in _interfaces) {
      withAddress(InternetAddress address) {
        try {
          Function.apply(joinMulticastFunction, [
            address
          ], {
            #interface: interface
          });
        } on NoSuchMethodError {
          Function.apply(joinMulticastFunction, [
            address,
            interface
          ]);
        }
      }

      try {
        withAddress(_v4_Multicast);
      } on SocketException {
        try {
          withAddress(_v6_Multicast);
        } on OSError {
        }
      }
    }
  }

  void stop() {
    if (_discoverySearchTimer != null) {
      _discoverySearchTimer.cancel();
      _discoverySearchTimer = null;
    }

    _socket.close();

    if (!_clientController.isClosed) {
      _clientController.close();
      _clientController = new StreamController<DiscoveredClient>.broadcast();
    }
  }

  Stream<DiscoveredClient> get clients => _clientController.stream;

  void search([String searchTarget = "upnp:rootdevice"]) {
    var buff = new StringBuffer();

    buff.write("M-SEARCH * HTTP/1.1\r\n");
    buff.write("HOST:239.255.255.250:1900\r\n");
    buff.write('MAN:"ssdp:discover"\r\n');
    buff.write("MX:1\r\n");
    buff.write("ST:${searchTarget}\r\n");
    buff.write("USER-AGENT:unix/5.1 UPnP/1.1 crash/1.0\r\n\r\n");
    var data = UTF8.encode(buff.toString());

    _socket.send(data, _v4_Multicast, 1900);
  }

  Future<List<DiscoveredClient>> discoverClients({
    Duration timeout: const Duration(seconds: 5)
  }) async {
    var list = <DiscoveredClient>[];

    var sub = clients.listen((client) => list.add(client));

    if (_socket == null) {
      await start();
    }

    search();
    await new Future.delayed(timeout);
    sub.cancel();
    stop();
    return list;
  }

  Timer _discoverySearchTimer;

  Stream<DiscoveredClient> quickDiscoverClients({
    Duration timeout,
    Duration searchInterval: const Duration(seconds: 10),
    String query: "upnp:rootdevice"
  }) async* {
    if (_socket == null) {
      await start();
    }

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

    yield* clients;
  }

  Future<List<DiscoveredDevice>> discoverDevices({
    String type,
    Duration timeout: const Duration(seconds: 5)
  }) {
    return discoverClients(timeout: timeout).then((clients) {
      if (clients.isEmpty) {
        return [];
      }

      var uuids = clients
        .where((client) => client.usn != null)
        .map((client) => client.usn.split("::").first)
        .toSet();
      var devices = [];

      for (var uuid in uuids) {
        var deviceClients = clients.where((client) {
          return client != null &&
            client.usn != null &&
            client.usn.split("::").first == uuid;
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
    String type,
    Duration timeout: const Duration(seconds: 5)
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
      }
    }

    return list;
  }
}

class DiscoveredDevice {
  List<String> serviceTypes = [];
  String uuid;
  String location;

  Future<Device> getRealDevice() async {
    http.Response response;

    try {
      response = await UpnpCommon.httpClient.get(location).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null
      );
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
      doc = xml.parse(response.body);
    } on Exception catch (e) {
      throw new FormatException(
        "ERROR: Failed to parse"
          " device description. ${e}"
      );
    }

    if (doc.findAllElements("device").isEmpty) {
      throw new ArgumentError("Not SCPD Compatible");
    }

    return new Device.fromXml(location, doc);
  }
}

class DiscoveredClient {
  String st;
  String usn;
  String server;
  String location;
  Map<String, String> headers;

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

  Future<Device> getDevice() async {
    Uri uri;

    try {
      uri = Uri.parse(location);
    } catch (e) {
      return null;
    }

    var response = await UpnpCommon.httpClient
      .get(uri)
      .timeout(const Duration(seconds: 3));

    if (response.statusCode != 200) {
      throw new Exception(
        "ERROR: Failed to fetch device description."
          " Status Code: ${response.statusCode}"
      );
    }

    XmlDocument doc;

    try {
      doc = xml.parse(response.body);
    } on Exception catch (e) {
      throw new FormatException(
        "ERROR: Failed to parse device"
          " description. ${e}");
    }

    return new Device.fromXml(location, doc);
  }
}
