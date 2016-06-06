import "dart:io";

main() async {
  var results = await NetworkInterface.list();

  print(results);
}
