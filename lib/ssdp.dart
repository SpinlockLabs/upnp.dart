library ssdp;

import "dart:async";
import "dart:convert";
import "dart:io";

class SSDP {
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
            var headers = {};
            var data = UTF8.decode(packet.data);
            var client =  new DiscoveredClient();
            var parts = data.split("\r\n");
            parts.removeAt(0);
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
  
  void broadcast() {
    var buff = new StringBuffer();
    
    buff.write("M-SEARCH * HTTP/1.1\r\n");
    buff.write("HOST: 239.255.255.250:1900\r\n");
    buff.write('MAN: "ssdp:discover"\r\n');
    buff.write("MX: 5\r\n");
    buff.write("ST: ssdp:all\r\n\r\n");
    var data = UTF8.encode(buff.toString());
    _socket.send(data, new InternetAddress("239.255.255.250"), 1900);
  }
  
  Future<List<DiscoveredClient>> discoverClients() {
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
      broadcast();
      new Future.delayed(new Duration(seconds: 2), () {
        sub.cancel();
        stop();
        completer.complete(list);
      });
    });
    
    return completer.future;
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
}