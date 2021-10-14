library upnp.utils;

import "dart:io";

import "package:xml/xml.dart" hide parse;

class UpnpException {
  final XmlElement element;

  UpnpException(this.element);

  @override
  String toString() => element.toXmlString();
}

class XmlUtils {
  static XmlElement getElementByName(XmlElement node, String name) {
    return node.findElements(name).first;
  }

  static String? getTextSafe(XmlElement node, String name) {
    var elements = node.findElements(name);
    if (elements.isEmpty) {
      return null;
    }
    return elements.first.text;
  }

  static String unescape(String input) {
    return input.replaceAll("&gt;", ">").replaceAll("&lt;", "<");
  }

  static dynamic asRichValue(String value) {
    if (value == null) {
      return null;
    }

    if (value.toLowerCase() == "true") {
      return true;
    }

    if (value.toLowerCase() == "false") {
      return false;
    }

    if (value.toLowerCase() == "null") {
      return null;
    }

    var number = num.tryParse(value);

    if (number != null) {
      return number;
    }

    return value;
  }

  static dynamic asValueType(input, String? type) {
    if (input == null) {
      return null;
    }

    if (type is String) {
      type = type.toLowerCase();
    }

    if (type == "string") {
      return input.toString();
    } else if (type == "number" ||
      type == "integer" ||
      type == "int" ||
      type == "double" ||
      type == "float") {
      return num.tryParse(input.toString());
    } else {
      return input.toString();
    }
  }
}

class UpnpCommon {
  static HttpClient httpClient = new HttpClient();
}
