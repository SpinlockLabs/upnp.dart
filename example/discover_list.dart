import "package:upnp/upnp.dart";

main() async {
  var disc = new DeviceDiscoverer();
  disc.quickDiscoverClients().listen((client) async {
    try {
      var dev = await client.getDevice();
      print(dev.friendlyName);
    } catch (e) {
      print("ERROR: ${e} - ${client.location}");
    }
  });
}
