import "package:upnp/dial.dart";

main() async {
  var dial = new DialScreen.forCastDevice("192.168.1.4");
  var isAppRunning = !(await dial.isIdle());
  if (isAppRunning) {
    print("An application is running.");
  } else {
    print("No application is running.");
  }
}
