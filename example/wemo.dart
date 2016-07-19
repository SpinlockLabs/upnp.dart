import "package:upnp/upnp.dart";

main() async {
  var discover = new DeviceDiscoverer();

  DiscoveredClient client = await discover.quickDiscoverClients(query: "urn:Belkin:device:controllee:1").first;
  var device = await client.getDevice();

  print("Device: ${device.friendlyName}");

  var service = await device.getService("urn:Belkin:service:basicevent:1");
  var sub = new StateSubscriptionManager();
  await sub.init();
  var v = service.stateVariables.firstWhere((x) => x.name == "BinaryState");
  sub.subscribe(v).listen((dynamic value) {
    print(value);
  });
}
