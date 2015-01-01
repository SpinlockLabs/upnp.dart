part of ssdp;

class WemoHelper {
  static Map<String, dynamic> parseAttributes(String input) {
    var doc = xml.parse("<attributes>" + XmlUtils.unescape(input) + "</attributes>").rootElement;
    var attr = {};
    doc.children.where((it) => it is XmlElement).forEach((element) {
      var name = element.findElements("name").first.text.trim();
      var value = element.findElements("value").first.text.trim();
      
      try {
        value = num.parse(value);
      } catch (e) {}
      
      value = value == "true" || value == "false" ? value == "true" : value;
      
      attr[name] = value;
    });
    return attr;
  }
  
  static String encodeAttributes(Map<String, dynamic> attr) {
    var buff = new StringBuffer();
    for (var key in attr.keys) {
      buff.write("<attribute><name>${key}</name><value>${attr[key]}</value></attribute>");
    }
    return buff.toString().replaceAll(">", "&gt;").replaceAll("<", "&lt;");
  }
}