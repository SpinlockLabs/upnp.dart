part of upnp.router;

class Router {
  static Future<Router> find() async {
    try {
      var discovery = new DeviceDiscoverer();
      var client = await discovery.quickDiscoverClients(
        timeout: const Duration(seconds: 10),
        query: CommonDevices.WAN_ROUTER
      ).first;

      var device = await client.getDevice();
      discovery.stop();
      var router = new Router(device);
      await router.init();
      return router;
    } catch (e) {
      return null;
    }
  }

  final Device device;

  Service _wanExternalService;
  Service _wanCommonService;
  Service _wanEthernetLinkService;

  Router(this.device);

  bool get hasEthernetLink => _wanEthernetLinkService != null;

  Future init() async {
    _wanExternalService = await device.getService("urn:upnp-org:serviceId:WANIPConn1");
    _wanCommonService = await device.getService("urn:upnp-org:serviceId:WANCommonIFC1");
    _wanEthernetLinkService = await device.getService("urn:upnp-org:serviceId:WANEthLinkC1");
  }

  Future<String> getExternalIpAddress() async {
    var result = await _wanExternalService.invokeAction("GetExternalIPAddress", {});
    return result["NewExternalIPAddress"];
  }

  Future<int> getTotalBytesSent() async {
    var result = await _wanCommonService.invokeAction("GetTotalBytesSent", {});
    return num.parse(result["NewTotalBytesSent"], (_) => 0);
  }

  Future<int> getTotalBytesReceived() async {
    var result = await _wanCommonService.invokeAction("GetTotalBytesReceived", {});
    return num.parse(result["NewTotalBytesReceived"], (_) => 0);
  }

  Future<int> getTotalPacketsSent() async {
    var result = await _wanCommonService.invokeAction("GetTotalPacketsSent", {});
    return num.parse(result["NewTotalPacketsSent"], (_) => 0);
  }

  Future<int> getTotalPacketsReceived() async {
    var result = await _wanCommonService.invokeAction("GetTotalPacketsReceived", {});
    return num.parse(result["NewTotalPacketsReceived"], (_) => 0);
  }
}
