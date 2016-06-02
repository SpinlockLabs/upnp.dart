part of upnp;

class Action {
  Service service;
  String name;
  List<ActionArgument> arguments = [];

  Action();

  Action.fromXml(XmlElement e) {
    name = XmlUtils.getTextSafe(e, "name");

    var argumentLists = e.findElements("argumentList");
    if (argumentLists.isNotEmpty) {
      var argList = argumentLists.first;
      for (var argdef in argList.children.where((it) => it is XmlElement)) {
        var name = XmlUtils.getTextSafe(argdef, "name");
        var direction = XmlUtils.getTextSafe(argdef, "direction");
        var relatedStateVariable = XmlUtils.getTextSafe(
          argdef,
          "relatedStateVariable"
        );
        var isRetVal = direction == "out";

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
    }
  }

  Future<Map<String, String>> invoke(Map<String, dynamic> args) async {
    var param = '  <u:${name} xmlns:u="${service.type}">' + args.keys.map((it) {
      return "<${it}>${args[it]}</${it}>";
    }).join("\n") + '</u:${name}>\n';

    var result = await service.sendToControlUrl(name, param);
    var response = xml.parse(result)
      .rootElement
      .firstChild
      .firstChild;

    if (const bool.fromEnvironment("upnp.action.show_response", defaultValue: false)) {
      print("Got Action Response: ${response.toXmlString()}");
    }

    if (response is XmlElement && !response.name.local.contains("Response")) {
      response = response.children[1];
    }

    List<XmlElement> results = response.children
      .where((it) => it is XmlElement).toList();
    var map = {};
    for (XmlElement r in results) {
      map[r.name.local] = r.text;
    }
    return map;
  }
}

class StateVariable {
  String name;
  String dataType;
  dynamic defaultValue;

  StateVariable();

  StateVariable.fromXml(XmlElement e) {
    name = XmlUtils.getTextSafe(e, "name");
    dataType = XmlUtils.getTextSafe(e, "dataType");
    defaultValue = XmlUtils.asValueType(
      XmlUtils.getTextSafe(e, "defaultValue"),
      dataType
    );
  }
}

class ActionArgument {
  final Action action;
  final String name;
  final String direction;
  final String relatedStateVariable;
  final bool isRetVal;

  ActionArgument(
    this.action,
    this.name,
    this.direction,
    this.relatedStateVariable,
    this.isRetVal);

  StateVariable getStateVariable() {
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
