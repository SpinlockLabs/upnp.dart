import "package:upnp/upnp.dart";

void main() {
  var discover = new DeviceDiscoverer();

  discover.getDevices(type: CommonDevices.WEMO).then((devices) {
    return devices.where((it) => it.modelName == "CoffeeMaker");
  }).then((devices) {
    for (var device in devices) {
      Service? service;
      device.getService("urn:Belkin:service:deviceevent:1").then((_) {
        service = _;
        return service!.invokeAction("GetAttributes", {});
      }).then((result) {
        var attributes = WemoHelper.parseAttributes(result["attributeList"]!);
        var brewing = attributes["Brewing"];
        var brewed = attributes["Brewed"];
        var mode = attributes["Mode"];
        print("Mode: ${mode}");
        print("Brewing: ${brewing}");
        print("Brewed: ${brewed}");
      });
    }
  });
}
