part of ssdp;

class DeviceDiscoverer {
  RawDatagramSocket _socket;
  StreamController<DiscoveredClient> _clientController = new StreamController.broadcast();
  
  Future start() {
    return RawDatagramSocket.bind("0.0.0.0", 1901).then((socket) {
      _socket = socket;
      socket.multicastHops = 10;
      socket.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            var packet = socket.receive();
            socket.writeEventsEnabled = true;
            
            if (packet == null) {
              return;
            }
            
            var data = UTF8.decode(packet.data);
            var parts = data.split("\r\n");
            var firstLine = parts.removeAt(0);
            
            if (firstLine.trim() == "HTTP/1.1 200 OK") {
              var headers = {};
              var client =  new DiscoveredClient();
              
              for (var part in parts) {
                var hp = part.split(": ");
                var name = hp[0];
                var value = (hp..removeAt(0)).join(": ").trim();
                headers[name] = value;
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
      
      socket.joinMulticast(new InternetAddress("239.255.255.250"));
    });
  }
  
  void stop() {
    _socket.close();
  }
  
  Stream<DiscoveredClient> get clients => _clientController.stream;
  
  void search([String searchTarget = "ssdp:all"]) {
    var buff = new StringBuffer();
    
    buff.write("M-SEARCH * HTTP/1.1\r\n");
    buff.write("HOST: 239.255.255.250:1900\r\n");
    buff.write('MAN: "ssdp:discover"\r\n');
    buff.write("MX: 5\r\n");
    buff.write("ST: ${searchTarget}\r\n\r\n");
    var data = UTF8.encode(buff.toString());
    _socket.send(data, new InternetAddress("239.255.255.250"), 1900);
  }
  
  Future<List<DiscoveredClient>> discoverClients({Duration timeout: const Duration(seconds: 3)}) {
    var completer = new Completer();
    StreamSubscription sub;
    var list = [];
    sub = clients.listen((client) {
      list.add(client);
    });
    
    var f = new Future.value();
    
    if (_socket == null) {
      f = start();
    }
    
    f.then((_) {
      search();
      new Future.delayed(timeout, () {
        sub.cancel();
        stop();
        completer.complete(list);
      });
    });
    
    return completer.future;
  }
  
  Future<List<DiscoveredDevice>> discoverDevices({String type, Duration timeout: const Duration(seconds: 3)}) {
    return discoverClients(timeout: timeout).then((clients) {
      try {
        var uuids = clients.map((client) => client.usn.substring("uuid:".length).split("::").first).toSet();
        var devices = [];
        
        for (var uuid in uuids) {
          var deviceClients = clients.where((client) => client.usn.substring("uuid:".length).split("::").first == uuid).toList();
          var location = deviceClients.first.location;
          var serviceTypes = deviceClients.map((it) => it.st).toSet().toList();
          var device = new DiscoveredDevice();
          device.servicesTypes = serviceTypes;
          device.uuid = uuid;
          device.location = location;
          if (type == null || serviceTypes.contains(type)) {
            devices.add(device);
          }
        }
        
        return devices;
      } on NoSuchMethodError catch (e) {
        print("No devices found");
        exit(1);
      }
    });
  }
  
  Future<List<Device>> getDevices({String type, Duration timeout: const Duration(seconds: 3)}) {
    var group = new FutureGroup();
    discoverDevices(type: type, timeout: timeout).then((results) {
      for (var result in results) {
        group.add(result.getDeviceDescription());
      }
    });
    return group.future;
  }
}

class DiscoveredDevice {
  List<String> servicesTypes = [];
  String uuid;
  String location;

  Future<Device> getDeviceDescription() {
    return http.get(location).then((response) {
      if (response.statusCode != 200) {
        throw new Exception("ERROR: Failed to fetch device description. Status Code: ${response.statusCode}");
      }
      
      XmlDocument doc;
      
      try {
        doc = xml.parse(response.body);
      } on Exception catch (e) {
        throw new FormatException("ERROR: Failed to parse device description. ${e}");
      }
      
      return new Device.fromXml(location, doc);
    });
  }
}

class DiscoveredClient {
  String st;
  String usn;
  String server;
  String location;
  Map<String, String> headers;
  
  String toString() {
    var buff = new StringBuffer();
    buff.writeln("ST: ${st}");
    buff.writeln("USN: ${usn}");
    buff.writeln("SERVER: ${server}");
    buff.writeln("LOCATION: ${location}");
    return buff.toString();
  }
  
  Future<Device> getDeviceDescription() {
    return http.get(location).then((response) {
      if (response.statusCode != 200) {
        throw new Exception("ERROR: Failed to fetch device description. Status Code: ${response.statusCode}");
      }
      
      XmlDocument doc;
      
      try {
        doc = xml.parse(response.body);
      } on Exception catch (e) {
        throw new FormatException("ERROR: Failed to parse device description. ${e}");
      }
      
      return new Device.fromXml(location, doc);
    });
  }
}
