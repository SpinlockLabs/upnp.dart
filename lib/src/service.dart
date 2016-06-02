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
  String type;
  String id;
  String controlUrl;
  String eventSubUrl;
  String scpdUrl;

  ServiceDescription.fromXml(String urlBase, XmlElement service) {
    type = XmlUtils.getTextSafe(service, "serviceType").trim();
    id = XmlUtils.getTextSafe(service, "serviceId").trim();
    controlUrl = urlBase + XmlUtils.getTextSafe(service, "controlURL").trim();
    eventSubUrl = urlBase + XmlUtils.getTextSafe(service, "eventSubURL").trim();

    var m = XmlUtils.getTextSafe(service, "SCPDURL");

    if (m != null) {
      if (m.startsWith("http:") || m.startsWith("https:")) {
        scpdUrl = m;
      } else {
        scpdUrl = urlBase + m;
      }
    }
  }

  Future<Service> getService() async {
    if (scpdUrl == null) {
      throw new Exception("Unable to fetch service, no SCPD URL.");
    }

    var response = await UpnpCommon.httpClient.get(scpdUrl)
      .timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (response == null) {
      return null;
    }

    if (response.statusCode != 200) {
      return null;
    }

    XmlElement doc;

    try {
      doc = xml.parse(response.body.replaceAll("ï»¿", "")).rootElement;
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
    return service;
  }
}

class Service {
  final String type;
  final String id;
  final List<Action> actions;
  final List<StateVariable> stateVariables;

  String controlUrl;
  String eventSubUrl;
  String scpdUrl;

  Service(
    this.type,
    this.id,
    this.controlUrl,
    this.eventSubUrl,
    this.scpdUrl,
    this.actions,
    this.stateVariables);

  Future<String> sendToControlUrl(String name, String param) async {
    var body = _SOAP_BODY.replaceAll("{param}", param);

    var response = await UpnpCommon.httpClient.post(
      controlUrl,
      body: body,
      headers: {
      "SOAPACTION": '"${type}#${name}"',
      "Content-Type": 'text/xml; charset="utf-8"',
      "User-Agent": 'CyberGarage-HTTP/1.0'
    });

    if (response.statusCode != 200) {
      try {
        var content = response.body;
        var doc = xml.parse(content);
        throw new UpnpException(doc.rootElement);
      } catch (e) {
        throw new Exception("\n\n${response.body}");
      }
    } else {
      return response.body;
    }
  }

  Future<Map<String, String>> invokeAction(
    String name,
    Map<String, dynamic> args) async {
    return await actions.firstWhere((it) => it.name == name).invoke(args);
  }
}

