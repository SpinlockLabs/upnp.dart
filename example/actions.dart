import "package:upnp/upnp.dart";

main() async {
  var client = new DiscoveredClient.fake("http://192.168.1.4:49153/setup.xml");
  var device = await client.getDevice();
  var service = await device.getService("urn:Belkin:service:deviceinfo:1");
  var result = await service.invokeAction("GetDeviceInformation", {});
  print(result);
}
