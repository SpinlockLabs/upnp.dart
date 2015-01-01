part of ssdp;

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
      scpdUrl = urlBase + m;
    }
  }
  
  Future<Service> getService() {
    if (scpdUrl == null) {
      throw new Exception("Unable to fetch service, no SCPD URL.");
    }
    
    return http.get(scpdUrl).then((response) {
      if (response.statusCode != 200) {
        throw new Exception("Failed to fetch service!");
      }
      var doc = xml.parse(response.body.replaceAll("ï»¿", "")).rootElement;
      var actionList = doc.findElements("actionList");
      var acts = [];
      
      if (actionList.isNotEmpty) {
        for (var e in actionList.first.children) {
          if (e is XmlElement) {
            acts.add(new Action.fromXml(e));
          }
        }
      }
      
      var service = new Service(type, id, controlUrl, eventSubUrl, scpdUrl, acts);
      for (var act in acts) {
        act.service = service;
      }
      return service;
    });
  }
}

class Service {
  final String controlUrl;
  final String eventSubUrl;
  final String scpdUrl;
  final String type;
  final String id;
  final List<Action> actions;

  Service(this.type, this.id, this.controlUrl, this.eventSubUrl, this.scpdUrl, this.actions);

  Future<String> sendToControlUrl(String name, String param) {
    var body = _SOAP_BODY.replaceAll("{param}", param);
    
    return http.post(controlUrl, body: body, headers: {
      "SOAPACTION": '"${type}#${name}"',
      "Content-Type": 'text/xml; charset="utf-8"',
      "User-Agent": 'CyberGarage-HTTP/1.0'
    }).then((response) {
      if (response.statusCode != 200) {
        throw new Exception("\n\n${response.body}");
      } else {
        return response.body;
      }
    });
  }
  
  Future<Map<String, String>> invokeAction(String name, Map<String, dynamic> args) {
    return actions.firstWhere((it) => it.name == name).invoke(args);
  }
}
