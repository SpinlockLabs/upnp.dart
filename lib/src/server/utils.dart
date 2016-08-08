part of upnp.server;

class UpnpHostUtils {
  static Future<String> getCurrentIp() async {
    var ip = const String.fromEnvironment("upnp.host.ip", defaultValue: null);
    if (ip != null) {
      return ip;
    }

    var interfaces = await NetworkInterface.list();
    for (var iface in interfaces) {
      for (var addr in iface.addresses) {
        if (addr.address.startsWith("192.") ||
          addr.address.startsWith("10.") ||
          addr.address.startsWith("172.")) {
          return addr.address;
        }
      }
    }

    return interfaces.first.addresses
      .firstWhere((x) => !x.isLoopback && !x.isLinkLocal)
      .address;
  }

  static String generateBasicId({int length: 30}) {
    var r0 = new Random();
    var buffer = new StringBuffer();
    for (int i = 1; i <= length; i++) {
      var r = new Random(r0.nextInt(0x70000000) + (new DateTime.now()).millisecondsSinceEpoch);
      var n = r.nextInt(50);
      if (n >= 0 && n <= 32) {
        String letter = alphabet[r.nextInt(alphabet.length)];
        buffer.write(r.nextBool() ? letter.toLowerCase() : letter);
      } else if (n > 32 && n <= 43) {
        buffer.write(numbers[r.nextInt(numbers.length)]);
      } else if (n > 43) {
        buffer.write(specials[r.nextInt(specials.length)]);
      }
    }
    return buffer.toString();
  }

  static String generateToken({int length: 50}) {
    var r0 = new Random();
    var buffer = new StringBuffer();
    for (int i = 1; i <= length; i++) {
      var r = new Random(r0.nextInt(0x70000000) + (new DateTime.now()).millisecondsSinceEpoch);
      if (r.nextBool()) {
        String letter = alphabet[r.nextInt(alphabet.length)];
        buffer.write(r.nextBool() ? letter.toLowerCase() : letter);
      } else {
        buffer.write(numbers[r.nextInt(numbers.length)]);
      }
    }
    return buffer.toString();
  }

  static const List<String> alphabet = const [
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z"
  ];

  static const List<int> numbers = const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  static const List<String> specials = const ["@", "=", "_", "+", "-", "!", "."];
}
