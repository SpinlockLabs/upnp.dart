import "package:upnp/upnp.dart";
import "package:quiver/async.dart";

void main() {
  var discoverer = new DeviceDiscoverer();

  discoverer.getDevices().then((devices) {
    var allGroup = new FutureGroup();

    for (var device in devices) {
      var group = new FutureGroup();

      for (var service in device.services) {
        group.add(service.getService().catchError((e) {
          return service;
        }));
      }

      allGroup.add(group.future.then((services) {
        return {
          "device": device,
          "services": services
        };
      }));
    }

    return allGroup.future;
  }).then((stuff) {
    for (var it in stuff) {
      Device device = it["device"];
      var services = it["services"];

      print("- ${device.modelName} by ${device.manufacturer} (uuid: ${device.uuid})");
      print("- URL: ${device.url}");

      for (var service in services) {
        if (service == null) {
          continue;
        }

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
    }
  });
}
