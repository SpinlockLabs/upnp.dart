part of upnp;

class Device {
  late XmlElement deviceElement;

  String? deviceType;
  String? urlBase;
  String? friendlyName;
  String? manufacturer;
  String? modelName;
  String? udn;
  String? uuid;
  String? url;
  String? presentationUrl;
  String? modelType;
  String? modelDescription;
  String? modelNumber;
  String? manufacturerUrl;

  List<Icon> icons = [];
  List<ServiceDescription> services = [];

  List<String?> get serviceNames => services.map((x) => x.id).toList();

  void loadFromXml(String? u, XmlElement e) {
    url = u;
    deviceElement = e;

    var uri = Uri.parse(url!);

    urlBase = XmlUtils.getTextSafe(deviceElement, "URLBase");

    if (urlBase == null) {
      urlBase = uri.toString();
    }

    if (deviceElement.findElements("device").isEmpty) {
      throw new Exception("ERROR: Invalid Device XML!\n\n${deviceElement}");
    }

    var deviceNode = XmlUtils.getElementByName(deviceElement, "device");

    deviceType = XmlUtils.getTextSafe(deviceNode, "deviceType");
    friendlyName = XmlUtils.getTextSafe(deviceNode, "friendlyName");
    modelName = XmlUtils.getTextSafe(deviceNode, "modelName");
    manufacturer = XmlUtils.getTextSafe(deviceNode, "manufacturer");
    udn = XmlUtils.getTextSafe(deviceNode, "UDN");
    presentationUrl = XmlUtils.getTextSafe(deviceNode, "presentationURL");
    modelType = XmlUtils.getTextSafe(deviceNode, "modelType");
    modelDescription = XmlUtils.getTextSafe(deviceNode, "modelDescription");
    manufacturerUrl = XmlUtils.getTextSafe(deviceNode, "manufacturerURL");

    if (udn != null) {
      uuid = udn!.substring("uuid:".length);
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

          icon.url = url;

          icons.add(icon);
        }
      }
    }

    Uri baseUri = Uri.parse(urlBase!);

    processDeviceNode(XmlElement e) {
      if (e.findElements("serviceList").isNotEmpty) {
        var list = e.findElements("serviceList").first;
        for (var svc in list.children) {
          if (svc is XmlElement) {
            services.add(new ServiceDescription.fromXml(baseUri, svc));
          }
        }
      }

      if (e.findElements("deviceList").isNotEmpty) {
        var list = e.findElements("deviceList").first;
        for (var dvc in list.children) {
          if (dvc is XmlElement) {
            processDeviceNode(dvc);
          }
        }
      }
    }

    processDeviceNode(deviceNode);
  }

  Future<Service?> getService(String type) async {
    var service = services.firstWhereOrNull(
      (it) => it.type == type || it.id == type);

    if (service != null) {
      return await service.getService(this);
    } else {
      return null;
    }
  }
}

class Icon {
  String? mimetype;
  int? width;
  int? height;
  int? depth;
  String? url;
}

class CommonDevices {
  static const String DIAL = "urn:dial-multiscreen-org:service:dial:1";
  static const String CHROMECAST = DIAL;
  static const String WEMO = "urn:Belkin:device:controllee:1";
  static const String WIFI_ROUTER = "urn:schemas-wifialliance-org:device:WFADevice:1";
  static const String WAN_ROUTER = "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1";
}
