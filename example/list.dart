import "package:ssdp/ssdp.dart";

void main() {
  var ssdp = new SSDP();
  
  ssdp.discoverClients().then((clients) {
    for (var client in clients) {
      print(client);
    }
  });
}