part of upnp;

class Device {
  late XmlElement deviceElement;

  String deviceType;
  String urlBase;
  String friendlyName;
  String manufacturer;
  String modelName;
  String udn;
  String uuid;
  String url;
  String presentationUrl;
  String modelType;
  String modelDescription;
  String manufacturerUrl;

  List<UpnpIcon> icons = [];
  List<ServiceDescription> services = [];

  List<String?> get serviceNames => services.map((x) => x.id).toList();

  Device._(
      {required this.deviceElement,
      required this.modelDescription,
      required this.modelName,
      required this.manufacturer,
      required this.friendlyName,
      required this.url,
      required this.deviceType,
      required this.icons,
      required this.manufacturerUrl,
      required this.modelType,
      required this.presentationUrl,
      required this.services,
      required this.udn,
      required this.urlBase,
      required this.uuid});

  factory Device.loadFromXml(String? u, XmlElement e) {
    var url = u;
    var deviceElement = e;

    var uri = Uri.parse(url!);

    var urlBase = XmlUtils.getTextSafe(deviceElement, "URLBase");

    if (urlBase == null) {
      urlBase = uri.toString();
    }

    if (deviceElement.findElements("device").isEmpty) {
      throw new Exception("ERROR: Invalid Device XML!\n\n${deviceElement}");
    }

    var deviceNode = XmlUtils.getElementByName(deviceElement, "device");

    var deviceType = XmlUtils.getTextDefault(deviceNode, "deviceType");
    var friendlyName = XmlUtils.getTextDefault(deviceNode, "friendlyName");
    var modelName = XmlUtils.getTextDefault(deviceNode, "modelName");
    var manufacturer = XmlUtils.getTextDefault(deviceNode, "manufacturer");
    var udn = XmlUtils.getTextDefault(deviceNode, "UDN");
    var presentationUrl =
        XmlUtils.getTextDefault(deviceNode, "presentationURL");
    var modelType = XmlUtils.getTextDefault(deviceNode, "modelType");
    var modelDescription =
        XmlUtils.getTextDefault(deviceNode, "modelDescription");
    var manufacturerUrl =
        XmlUtils.getTextDefault(deviceNode, "manufacturerURL");
    var uuid = udn.substring("uuid:".length);
    List<UpnpIcon> icons = [];
    List<ServiceDescription> services = [];

    if (deviceNode.findElements("iconList").isNotEmpty) {
      var iconList = deviceNode.findElements("iconList").first;
      for (var child in iconList.children) {
        if (child is XmlElement) {
          var icon = new UpnpIcon(
              mimetype: XmlUtils.getTextSafe(child, "mimetype") ?? '',
              url: XmlUtils.getTextSafe(child, "url") ?? '');
          var width = XmlUtils.getTextSafe(child, "width");
          var height = XmlUtils.getTextSafe(child, "height");
          var depth = XmlUtils.getTextSafe(child, "depth");
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

    Uri baseUri = Uri.parse(urlBase);

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

    return Device._(
        uuid: uuid,
        udn: udn,
        url: url,
        urlBase: urlBase,
        deviceElement: deviceElement,
        deviceType: deviceType,
        modelDescription: modelDescription,
        manufacturer: manufacturer,
        manufacturerUrl: manufacturerUrl,
        friendlyName: friendlyName,
        modelName: modelName,
        icons: icons,
        services: services,
        presentationUrl: presentationUrl,
        modelType: modelType);
  }

  Future<Service?> getService(String type) async {
    var service =
        services.firstWhereOrNull((it) => it.type == type || it.id == type);

    if (service != null) {
      return await service.getService(this);
    } else {
      return null;
    }
  }
}

class UpnpIcon {
  String mimetype;
  int? width;
  int? height;
  int? depth;
  String url;

  UpnpIcon({required this.mimetype, required this.url});
}

class CommonDevices {
  static const String DIAL = "urn:dial-multiscreen-org:service:dial:1";
  static const String CHROMECAST = DIAL;
  static const String WEMO = "urn:Belkin:device:controllee:1";
  static const String WIFI_ROUTER =
      "urn:schemas-wifialliance-org:device:WFADevice:1";
  static const String WAN_ROUTER =
      "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1";
  static const String CANON_CAMERA =
      "urn:schemas-canon-com:device:ICPO- CameraControlAPIService:1";
}
