import "dart:async";
import "package:upnp/upnp.dart";

void main() {
  var discover = new DeviceDiscoverer();

  discover.getDevices(type: CommonDevices.WEMO).then((devices) {
    return devices.where((it) => it.modelName == "Socket");
  }).then((devices) {
    for (var device in devices) {
      Service service;
      device.getService("urn:Belkin:service:basicevent:1").then((_) {
        service = _;
        toggle(service);
      });
    }
  });
}

void toggle(Service service) {
  service.invokeAction("GetBinaryState", {}).then((result) {
    var state = int.parse(result["BinaryState"]);

    service.invokeAction("SetBinaryState", {
      "BinaryState": state == 0 ? 1 : 0
    });
  });
}
