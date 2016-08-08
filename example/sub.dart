import "dart:async";
import "package:upnp/upnp.dart";

import "package:stack_trace/stack_trace.dart";
import "package:upnp/src/utils.dart";

main() async {
  await Chain.capture(() async {
    var discover = new DeviceDiscoverer();

    List<Device> devices = await discover.getDevices();

    var sub = new StateSubscriptionManager();
    await sub.init();

    for (Device device in devices) {
      for (ServiceDescription desc in device.services) {
        Service service;

        try {
          service = await desc.getService(device).timeout(const Duration(seconds: 5));
        } catch (e) {}

        if (service != null) {
          try {
            sub.subscribeToService(service).listen((value) {
              print("${device.friendlyName} - ${service.id}: ${value}");
            }, onError: (e, stack) {
              print("Error while subscribing to ${service.type} for ${device.friendlyName}: ${e}");
            });
          } catch (e) {
          }
        }
      }
    }

    new Timer(const Duration(seconds: 60), () {
      print("Ended.");
      sub.close();

      Timer.run(() {
        UpnpCommon.httpClient.close();
      });
    });
  });
}
