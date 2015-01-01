import "package:ssdp/ssdp.dart";

void main() {
  var discover = new DeviceDiscoverer();
  
  discover.getDevices(type: CommonDevices.WEMO).then((devices) {
    return devices.where((it) => it.modelName == "Socket");
  }).then((devices) {
    for (var device in devices) {
      Service service;
      device.getService("urn:Belkin:service:basicevent:1").then((_) {
        service = _;
        return service.invokeAction("GetBinaryState", {});
      }).then((result) {
        var state = int.parse(result["BinaryState"]);
        
        service.invokeAction("SetBinaryState", {
          "BinaryState": state == 0 ? 1 : 0
        });
      });
    }
  });
}