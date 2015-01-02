part of ssdp;

class Device {
  String deviceType;
  String urlBase;
  String friendlyName;
  String manufacturer;
  String modelName;
  String udn;
  String uuid;
  List<Icon> icons = [];
  List<ServiceDescription> services = [];
  
  Device.fromXml(String url, XmlDocument doc) {
    var uri = Uri.parse(url);
    var document = doc.rootElement;
    
    urlBase = XmlUtils.getTextSafe(document, "URLBase");
    
    if (urlBase == null) {
      urlBase = uri.origin;
    }
    
    var deviceNode = XmlUtils.getElementByName(document, "device");
    
    deviceType = XmlUtils.getTextSafe(deviceNode, "deviceType");
    friendlyName = XmlUtils.getTextSafe(deviceNode, "friendlyName");
    modelName = XmlUtils.getTextSafe(deviceNode, "modelName");
    manufacturer = XmlUtils.getTextSafe(deviceNode, "manufacturer");
    udn = XmlUtils.getTextSafe(deviceNode, "UDN");
    
    if (udn != null) {
      uuid = udn.substring("uuid:".length);
    }
    
    if (deviceNode.findElements("iconList").isNotEmpty) {
      var iconList = deviceNode.findElements("iconList").first;
      for (var child in iconList.children) {
        if (child is XmlElement) {
          var icon = new Icon();
          icon.mimetype = XmlUtils.getTextSafe(child, "mimetype");
          var width = XmlUtils.getTextSafe(child, "width");
          var height = XmlUtils.getTextSafe(child, "height");
          var depth = XmlUtils.getTextSafe(child, "depth");
          var url = XmlUtils.getTextSafe(child, "url");
          if (width != null) {
            icon.width = int.parse(width);
          }
          
          if (height != null) {
            icon.height = int.parse(height);
          }
          
          if (depth != null) {
            icon.depth = int.parse(depth);
          }
          
          icon.url;
          
          icons.add(icon);
        }
      }
    }
    
    if (deviceNode.findElements("serviceList").isNotEmpty) {
      var list = deviceNode.findElements("serviceList").first;
      for (var e in list.children) {
        if (e is XmlElement) {
          services.add(new ServiceDescription.fromXml(urlBase, e));
        }
      }
    }
  }
  
  Future<Service> getService(String type) {
    return services.firstWhere((it) => it.type == type).getService();
  }
}

class Icon {
  String mimetype;
  int width;
  int height;
  int depth;
  String url;
}

class CommonDevices {
  static const String CHROMECAST = "urn:dial-multiscreen-org:service:dial:1";
  static const String WEMO = "urn:Belkin:service:basicevent:1";
}