import "dart:async";

import "package:upnp/upnp.dart";
import "package:upnp/src/utils.dart";

Future printDevice(Device device) async {
  print("- ${device.modelName} by ${device.manufacturer} (uuid: ${device.uuid})");
  print("- URL: ${device.url}");

  if (device.services == null) {
    print("-----");
    return;
  }

  var svcs = <Service>[];

  for (var svc in device.services) {
    if (svc == null) {
      continue;
    }

    var service = await svc.getService();
    svcs.add(service);
  }

  for (var service in svcs) {
    if (service != null) {
      print("  - Type: ${service.type}");
      print("  - ID: ${service.id}");
      print("  - Control URL: ${service.controlUrl}");

      if (service.actions.isNotEmpty) {
        print("  - Actions:");
      }

      for (var action in service.actions) {
        print("    - Name: ${action.name}");
        print("    - Arguments: ${action.arguments
          .where((it) => it.direction == "in")
          .map((it) => it.name)
          .toList()}");
        print("    - Results: ${action.arguments
          .where((it) => it.direction == "out")
          .map((it) => it.name)
          .toList()}");

        print("");
      }

      if (service.stateVariables.isNotEmpty) {
        print("  - State Variables:");
      } else {
        print("");
      }

      for (var variable in service.stateVariables) {
        print("    - Name: ${variable.name}");
        print("    - Data Type: ${variable.dataType}");
        if (variable.defaultValue != null) {
          print("    - Default Value: ${variable.defaultValue}");
        }

        print("");
      }

      if (service.actions.isEmpty) {
        print("");
      }
    }
  }

  print("-----");
}

main(List<String> args) async {
  var discoverer = new DeviceDiscoverer();
  await discoverer.start(ipv6: false);
  await discoverer
    .quickDiscoverClients()
    .listen((DiscoveredClient client) async {
    Device device;

    try {
      device = await client.getDevice();
    } catch (e) {
      assert(print(e));
    }

    if (device == null || (args.isNotEmpty && !args.contains(device.uuid))) {
      return;
    }

    if (device != null) {
      await printDevice(device);
    }
  }).asFuture();

  await UpnpCommon.httpClient.close();
}
