import "package:ssdp/ssdp.dart";
import "dart:async";

void main() {
  var discover = new DeviceDiscoverer();

  discover.getDevices(type: CommonDevices.WEMO).then((devices) {
    return devices.where((it) => it.modelName == "Socket");
  }).then((devices) {
    for (var device in devices) {
      Service service;
      device.getService("urn:Belkin:service:basicevent:1").then((_) {
        service = _;
        var future = new Future.value();
        for (var i = 0; i < 7; i++) {
          future = future.then((_) {
            return new Future.delayed(new Duration(seconds: 2), () {
              toggle(service);
            });
          });
        }
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
