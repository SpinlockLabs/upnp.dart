part of upnp;

class Action {
  Service service;
  String name;
  List<ActionArgument> arguments = [];
  
  Action.fromXml(XmlElement e) {
    name = XmlUtils.getTextSafe(e, "name");
  
    var argumentLists = e.findElements("argumentList");
    if (argumentLists.isNotEmpty) {
      var argList = argumentLists.first;
      for (var argdef in argList.children.where((it) => it is XmlElement)) {
        var name = XmlUtils.getTextSafe(argdef, "name");
        var direction = XmlUtils.getTextSafe(argdef, "direction");
        var relatedStateVariable = XmlUtils.getTextSafe(argdef, "relatedStateVariable");
        var isRetVal = argdef.children.where((it) => it is XmlElement).any((child) => child.name.toString() == "retval");
        
        arguments.add(new ActionArgument(name, direction, relatedStateVariable, isRetVal));
      }
    }
  }
  
  Future<Map<String, String>> invoke(Map<String, dynamic> args) {
    var param = '  <u:${name} xmlns:u="${service.type}">' + args.keys.map((it) {
      return "<${it}>${args[it]}</${it}>";
    }).join("\n") + '</u:${name}>\n';
    return service.sendToControlUrl(name, param).then((result) {
      var response = xml.parse(result).firstChild.firstChild.children[1];
      var results = response.children.where((it) => it is XmlElement).map((it) => it.name.toString());
      var map = {};
      for (var r in results) {
        map[r] = response.findElements(r).first.text;
      }
      return map;
    });
  }
}

class ActionArgument {
  final String name;
  final String direction;
  final String relatedStateVariable;
  final bool isRetVal;
  
  ActionArgument(this.name, this.direction, this.relatedStateVariable, this.isRetVal);
}