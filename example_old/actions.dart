import 'dart:async';

import "package:upnp/upnp.dart";

main(List<String> args) async {
  var client = new DiscoveredClient.fake(args[0]);
  var device = await (client.getDevice() as FutureOr<Device>);
  print(device.services);
  var service = await (device.getService(args[1]) as FutureOr<Service>);
  var result = await service.invokeAction(args[2], {});
  print(result);
}
