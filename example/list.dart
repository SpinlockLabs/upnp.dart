import "package:upnp/upnp.dart";
import "dart:async";

Future printDevice(Device device) async {
  print("- ${device.modelName} by ${device.manufacturer} (uuid: ${device.uuid})");
  print("- URL: ${device.url}");

  if (device.services == null) {
    print("-----");
    return;
  }

  for (var svc in device.services) {
    if (svc == null) {
      continue;
    }

    var service = await svc.getService();
    print("  - Type: ${service.type}");
    print("  - ID: ${service.id}");
    print("  - Control URL: ${service.controlUrl}");

    if (service is Service) {
      if (service.actions.isNotEmpty) {
        print("  - Actions:");
      }

      for (var action in service.actions) {
        print("    - Name: ${action.name}");
        print("    - Arguments: ${action.arguments.where((it) => it.direction == "in").map((it) => it.name).toList()}");
        print("    - Results: ${action.arguments.where((it) => it.direction == "out").map((it) => it.name).toList()}");
        print("");
      }

      if (service.actions.isEmpty) {
        print("");
      }
    }
  }

  print("-----");
}

void main() {
  var discoverer = new DeviceDiscoverer();

  discoverer.getDevices(timeout: new Duration(seconds: 20)).then((devices) async {
    for (var device in devices) {
      await printDevice(device);
    }
  });
}
