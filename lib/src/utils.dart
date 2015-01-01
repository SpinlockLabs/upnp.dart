library ssdp.utils;

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
}

