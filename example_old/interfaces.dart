import "dart:io";

main() async {
  for (NetworkInterface iface in await NetworkInterface.list()) {
    print("${iface.name}:");
    for (InternetAddress address in iface.addresses) {
      print("  - ${address.address}");
    }
  }
}
