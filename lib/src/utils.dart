library upnp.utils;

import "dart:io";

import "package:xml/xml.dart" hide parse;
import "package:http/http.dart" as http;

class XmlUtils {
  static XmlElement getElementByName(XmlElement node, String name) {
    return node.findElements(name).first;
  }

  static String getTextSafe(XmlElement node, String name) {
    var elements = node.findElements(name);
    if (elements.isEmpty) {
      return null;
    }
    return elements.first.text;
  }

  static String unescape(String input) {
    return input.replaceAll("&gt;", ">").replaceAll("&lt;", "<");
  }
}

class UpnpCommon {
  static http.Client httpClient = new http.IOClient(
    new HttpClient()
      ..maxConnectionsPerHost = 10
  );
}
