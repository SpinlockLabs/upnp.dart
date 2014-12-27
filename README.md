# SSDP for Dart

Simple Service Discovery Protocol Client for Dart

## Usage

```dart
import "package:ssdp/ssdp.dart";

void main() {
  var ssdp = new SSDP();
  
  ssdp.discoverClients().then((clients) {
    var wemos = clients.where((it) => it.st == "urn:Belkin:service:basicevent:1");
    for (var wemo in wemos) {
      var uri = Uri.parse(wemo.location);
      var ip = uri.host;
      print("Found WeMo at ${ip}");
    }
  });
}
```
