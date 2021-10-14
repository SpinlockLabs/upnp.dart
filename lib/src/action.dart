part of upnp;

class Action {
  late Service service;
  String? name;
  List<ActionArgument> arguments = [];

  Action();

  Action.fromXml(XmlElement e) {
    name = XmlUtils.getTextSafe(e, "name");

    addArgDef(XmlElement argdef, [bool stripPrefix = false]) {
      var name = XmlUtils.getTextSafe(argdef, "name");

      if (name == null) {
        return;
      }

      var direction = XmlUtils.getTextSafe(argdef, "direction");
      var relatedStateVariable = XmlUtils.getTextSafe(
        argdef,
        "relatedStateVariable"
      );
      var isRetVal = direction == "out";

      if (this.name!.startsWith("Get")) {
        var of = this.name!.substring(3);
        if (of == name) {
          isRetVal = true;
        }
      }

      if (name.startsWith("Get") && stripPrefix) {
        name = name.substring(3);
      }

      arguments.add(
        new ActionArgument(
          this,
          name,
          direction,
          relatedStateVariable,
          isRetVal
        )
      );
    }

    var argumentLists = e.findElements("argumentList");
    if (argumentLists.isNotEmpty) {
      var argList = argumentLists.first;
      if (argList.children.any((x) => x is XmlElement && x.name.local == "name")) {
        // Bad UPnP Implementation fix for WeMo
        addArgDef(argList, true);
      } else {
        for (var argdef in argList.children.where((it) => it is XmlElement)) {
          addArgDef(argdef as XmlElement);
        }
      }
    }
  }

  Future<Map<String, String>> invoke(Map<String, dynamic> args) async {
    var param = '  <u:${name} xmlns:u="${service.type}">' + args.keys.map((it) {
      String argsIt = args[it].toString();
      argsIt = argsIt.replaceAll("&", "&amp;");
      return "<${it}>${argsIt}</${it}>";
    }).join("\n") + '</u:${name}>\n';

    var result = await service.sendToControlUrl(name, param);
    var doc = xml.parse(result);
    XmlElement response = doc
      .rootElement;

    if (response.name.local != "Body") {
      response = response.children.firstWhere((x) => x is XmlElement) as XmlElement;
    }

    if (const bool.fromEnvironment("upnp.action.show_response", defaultValue: false)) {
      print("Got Action Response: ${response.toXmlString()}");
    }

    if (response is XmlElement
      && !response.name.local.contains("Response") &&
      response.children.length > 1) {
      response = response.children[1] as XmlElement;
    }

    if (response.children.length == 1) {
      var d = response.children[0];

      if (d is XmlElement) {
        if (d.name.local.contains("Response")) {
          response = d;
        }
      }
    }

    if (const bool.fromEnvironment("upnp.action.show_response", defaultValue: false)) {
      print("Got Action Response (Real): ${response.toXmlString()}");
    }

    List<XmlElement> results = response.children
      .whereType<XmlElement>()
      .toList();
    var map = <String, String>{};
    for (XmlElement r in results) {
      map[r.name.local] = r.text;
    }
    return map;
  }
}

class StateVariable {
  late Service service;
  String? name;
  String? dataType;
  dynamic defaultValue;
  bool doesSendEvents = false;

  StateVariable();

  StateVariable.fromXml(XmlElement e) {
    name = XmlUtils.getTextSafe(e, "name");
    dataType = XmlUtils.getTextSafe(e, "dataType");
    defaultValue = XmlUtils.asValueType(
      XmlUtils.getTextSafe(e, "defaultValue"),
      dataType
    );
    doesSendEvents = e.getAttribute("sendEvents") == "yes";
  }

  String getGenericId() {
    return sha1.convert(utf8.encode(
      "${service.device!.uuid}::${service.id}::${name}"
    )).toString();
  }
}

class ActionArgument {
  final Action action;
  final String? name;
  final String? direction;
  final String? relatedStateVariable;
  final bool isRetVal;

  ActionArgument(
    this.action,
    this.name,
    this.direction,
    this.relatedStateVariable,
    this.isRetVal);

  StateVariable? getStateVariable() {
    if (relatedStateVariable != null) {
      return null;
    }

    Iterable<StateVariable> vars = action
      .service
      .stateVariables
      .where((x) => x.name == relatedStateVariable);

    if (vars.isNotEmpty) {
      return vars.first;
    }

    return null;
  }
}
