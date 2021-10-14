import "dart:io";

import "package:upnp/server.dart";

main() async {
  var device = new UpnpHostDevice(
    deviceType: "urn:schemas-upnp-org:device:Basic:1",
    friendlyName: "Dart Test Device",
    manufacturer: "Kenneth Endfinger",
    modelName: "Test Device",
    udn: "uuid:9a3b452a33cd4218e755c5b14f9c13ac57f5c2af754b2a9c0c3ff5919740c18e"
  );

  var helloService = new UpnpHostService(
    type: "urn:Kenneth-Endfinger:service:HelloWorld:1",
    id: "urn:Kenneth-Endfinger:serviceId:HelloWorld1",
    simpleName: "HelloWorld"
  );

  helloService.actions.add(new UpnpHostAction(
    "HelloWorld",
    handler: (params) => print("Hello World")
  ));

  device.services.add(helloService);

  var httpServer = await HttpServer.bind("0.0.0.0", 4021);
  var server = new UpnpServer(device);

  httpServer.listen(server.handleRequest);

  var discovery = new UpnpDiscoveryServer(device, "http://192.168.1.2:4021/upnp/root.xml");
  await discovery.start();
}
