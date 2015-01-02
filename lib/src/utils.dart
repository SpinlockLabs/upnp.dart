library upnp.utils;

import "package:xml/xml.dart" hide parse;

class XmlUtils {
  static XmlElement getElementByName(XmlBranch node, String name) {
    return node.findElements(name).first;
  }
  
  static String getTextSafe(XmlBranch node, String name) {
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

