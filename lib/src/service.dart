part of upnp;

const String _SOAP_BODY = """
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
  {param}
  </s:Body>
</s:Envelope>
""";

class ServiceDescription {
  String? type;
  String? id;
  String? controlUrl;
  String? eventSubUrl;
  String? scpdUrl;

  ServiceDescription.fromXml(Uri uriBase, XmlElement service) {
    type = XmlUtils.getTextSafe(service, "serviceType")!.trim();
    id = XmlUtils.getTextSafe(service, "serviceId")!.trim();
    controlUrl = uriBase.resolve(
      XmlUtils.getTextSafe(service, "controlURL")!.trim()
    ).toString();
    eventSubUrl = uriBase.resolve(
      XmlUtils.getTextSafe(service, "eventSubURL")!.trim()
    ).toString();

    var m = XmlUtils.getTextSafe(service, "SCPDURL");

    if (m != null) {
      scpdUrl = uriBase.resolve(m).toString();
    }
  }

  Future<Service?> getService([Device? device]) async {
    if (scpdUrl == null) {
      throw new Exception("Unable to fetch service, no SCPD URL.");
    }

    var request = await UpnpCommon.httpClient
      .getUrl(Uri.parse(scpdUrl!))
      .timeout(const Duration(seconds: 5), onTimeout: (() => null) as FutureOr<HttpClientRequest> Function()?);

    var response = await request.close();

    if (response == null) {
      return null;
    }

    if (response.statusCode != 200) {
      return null;
    }

    XmlElement doc;

    try {
      var content = await response.cast<List<int>>().transform(utf8.decoder).join();
      content = content.replaceAll("\u00EF\u00BB\u00BF", "");
      doc = xml.parse(content).rootElement;
    } catch (e) {
      return null;
    }

    var actionList = doc.findElements("actionList");
    var varList = doc.findElements("serviceStateTable");
    var acts = <Action>[];

    if (actionList.isNotEmpty) {
      for (var e in actionList.first.children) {
        if (e is XmlElement) {
          acts.add(new Action.fromXml(e));
        }
      }
    }

    var vars = <StateVariable>[];

    if (varList.isNotEmpty) {
      for (var e in varList.first.children) {
        if (e is XmlElement) {
          vars.add(new StateVariable.fromXml(e));
        }
      }
    }

    var service = new Service(
      device,
      type,
      id,
      controlUrl,
      eventSubUrl,
      scpdUrl,
      acts,
      vars
    );

    for (var act in acts) {
      act.service = service;
    }

    for (var v in vars) {
      v.service = service;
    }

    return service;
  }

  @override
  String toString() => "ServiceDescription(${id})";
}

class Service {
  final Device? device;
  final String? type;
  final String? id;
  final List<Action> actions;
  final List<StateVariable> stateVariables;

  String? controlUrl;
  String? eventSubUrl;
  String? scpdUrl;

  Service(
    this.device,
    this.type,
    this.id,
    this.controlUrl,
    this.eventSubUrl,
    this.scpdUrl,
    this.actions,
    this.stateVariables);

  List<String?> get actionNames => actions.map((x) => x.name).toList();

  Future<String> sendToControlUrl(String? name, String param) async {
    var body = _SOAP_BODY.replaceAll("{param}", param);

    if (const bool.fromEnvironment("upnp.debug.control", defaultValue: false)) {
      print("Send to ${controlUrl} (SOAPACTION: ${type}#${name}): ${body}");
    }

    var request = await UpnpCommon.httpClient.postUrl(Uri.parse(controlUrl!));
    request.headers.set("SOAPACTION", '"${type}#${name}"');
    request.headers.set("Content-Type", 'text/xml; charset="utf-8"');
    request.headers.set("User-Agent", 'CyberGarage-HTTP/1.0');
    request.write(body);
    var response = await request.close();

    var content = await response.cast<List<int>>().transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      try {
        var doc = xml.parse(content);
        throw new UpnpException(doc.rootElement);
      } catch (e) {
        if (e is! UpnpException) {
          throw new Exception("\n\n${content}");
        } else {
          rethrow;
        }
      }
    } else {
      return content;
    }
  }

  Future<Map<String, String>> invokeAction(
    String name,
    Map<String, dynamic> args) async {
    return await actions.firstWhere((it) => it.name == name).invoke(args);
  }
}
