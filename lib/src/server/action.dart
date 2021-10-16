part of upnp.server;

typedef HostActionHandler(Map<String, dynamic> params);

class UpnpHostAction {
  final String name;
  final List<UpnpHostActionArgument> inputs;
  final List<UpnpHostActionArgument> outputs;
  final HostActionHandler? handler;

  UpnpHostAction(this.name, {
    this.inputs: const [],
    this.outputs: const [],
    this.handler
  });

  void applyToXml(XML.XmlBuilder x) {
    x.element("action", nest: () {
      x.element("name", nest: name);
      x.element("argumentList", nest: () {
        for (var input in inputs) {
          input.applyToXml(x);
        }

        for (var out in outputs) {
          out.applyToXml(x);
        }
      });
    });
  }
}

class UpnpHostActionArgument {
  final String name;
  final bool isOutput;
  final String? relatedStateVariable;

  UpnpHostActionArgument(this.name, this.isOutput, {this.relatedStateVariable});

  void applyToXml(XML.XmlBuilder x) {
    x.element("argument", nest: () {
      x.element("name", nest: name);
      x.element("direction", nest: isOutput ? "out" : "in");

      if (relatedStateVariable != null) {
        x.element("relatedStateVariable", nest: relatedStateVariable);
      }
    });
  }
}
