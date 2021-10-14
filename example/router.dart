import "package:upnp/router.dart";

import "dart:io";

main() async {
  await for (var router in Router.findAll()) {
    var address = await router.getExternalIpAddress();
    print("Router ${Uri.parse(router.device!.url!).host}:");
    print("  External IP Address: ${address}");
    var totalBytesSent = await router.getTotalBytesSent();
    print("  Total Bytes Sent: ${totalBytesSent} bytes");
    var totalBytesReceived = await router.getTotalBytesReceived();
    print("  Total Bytes Received: ${totalBytesReceived} bytes");
    var totalPacketsSent = await router.getTotalPacketsSent();
    print("  Total Packets Sent: ${totalPacketsSent} bytes");
    var totalPacketsReceived = await router.getTotalPacketsReceived();
    print("  Total Packets Received: ${totalPacketsReceived} bytes");
  }

  exit(0);
}
