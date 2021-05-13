part of upnp.router;

class Router {
  static Future<Router?> find() async {
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

  static Stream<Router> findAll({
    bool silent: true,
    bool unique: true,
    bool enableIpv4Only: true,
    Duration timeout: const Duration(seconds: 10)
  }) async* {
    var discovery = new DeviceDiscoverer();
    await discovery.start(ipv4: true, ipv6: !enableIpv4Only);
    await for (DiscoveredClient client in discovery.quickDiscoverClients(
      timeout: timeout,
      query: CommonDevices.WAN_ROUTER,
      unique: unique
    )) {
      try {
        var device = await client.getDevice();
        var router = new Router(device);
        await router.init();
        yield router;
      } catch (e) {
        if (!silent) {
          rethrow;
        }
      }
    }
  }

  final Device? device;

  Service? _wanExternalService;
  Service? _wanCommonService;
  Service? _wanEthernetLinkService;

  Router(this.device);

  bool get hasEthernetLink => _wanEthernetLinkService != null;

  Future init() async {
    _wanExternalService = await device!.getService("urn:upnp-org:serviceId:WANIPConn1");
    _wanCommonService = await device!.getService("urn:upnp-org:serviceId:WANCommonIFC1");
    _wanEthernetLinkService = await device!.getService("urn:upnp-org:serviceId:WANEthLinkC1");
  }

  Future<String?> getExternalIpAddress() async {
    var result = await _wanExternalService!.invokeAction("GetExternalIPAddress", {});
    return result["NewExternalIPAddress"];
  }

  Future<int> getTotalBytesSent() async {
    var result = await _wanCommonService!.invokeAction("GetTotalBytesSent", {});
    return num.tryParse(result["NewTotalBytesSent"]!) as FutureOr<int>? ?? 0;
  }

  Future<int> getTotalBytesReceived() async {
    var result = await _wanCommonService!.invokeAction("GetTotalBytesReceived", {});
    return num.tryParse(result["NewTotalBytesReceived"]!) as FutureOr<int>? ?? 0;
  }

  Future<int> getTotalPacketsSent() async {
    var result = await _wanCommonService!.invokeAction("GetTotalPacketsSent", {});
    return num.tryParse(result["NewTotalPacketsSent"]!) as FutureOr<int>? ?? 0;
  }

  Future<int> getTotalPacketsReceived() async {
    var result = await _wanCommonService!.invokeAction("GetTotalPacketsReceived", {});
    return num.tryParse(result["NewTotalPacketsReceived"]!) as FutureOr<int>? ?? 0;
  }
}
