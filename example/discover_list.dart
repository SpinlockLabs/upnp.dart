import "package:upnp/upnp.dart";

main() async {
  var disc = new DeviceDiscoverer();
  await disc.start(ipv6: false);
  disc.quickDiscoverClients().listen((client) async {
    try {
      var dev = await client.getDevice();
      print("${dev!.friendlyName}: ${dev.url}");
    } catch (e, stack) {
      print("ERROR: ${e} - ${client.location}");
      print(stack);
    }
  });
}
