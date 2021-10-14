import 'package:flutter/material.dart';
import 'package:upnp/upnp.dart' as upnp;
import 'package:upnp/router.dart' as router;

void main() {
  runApp(const ExampleUpnp());
}

class ExampleUpnp extends StatelessWidget {
  const ExampleUpnp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upnp Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UpnpDemoPage(title: 'Upnp Demo Home Page'),
    );
  }
}

class UpnpDemoPage extends StatefulWidget {
  const UpnpDemoPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<UpnpDemoPage> createState() => _UpnpDemoState();
}

class _UpnpDemoState extends State<UpnpDemoPage> {
  final _disc = upnp.DeviceDiscoverer();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder(
            future: _disc.start(ipv6: false),
            builder: (context, data) {
              if (data.hasError) {
                return Text(data.error.toString());
              }
              if (data.hasData) {
                return _getBody();
              }
              return const Text('Loading devices...');
            }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Routers',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _getDevicesList() {
    return FutureBuilder(
      future: _disc.discoverDevices(),
      builder: (BuildContext context,
          AsyncSnapshot<List<upnp.DiscoveredDevice>> snapshot) {
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Text('Scanning...');
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Devices:',
            ),
            ...snapshot.requireData.map(
              (e) => FutureBuilder(
                  future: e.getRealDevice(),
                  builder:
                      (BuildContext context, AsyncSnapshot<upnp.Device> dev) {
                    if (dev.hasData) {
                      return Text(
                          "${dev.requireData.friendlyName} ${dev.requireData.url}");
                    }
                    if (dev.hasError) {
                      return Text(dev.error.toString());
                    }
                    return const Text('Loading device...');
                  }),
            )
          ],
        );
      },
    );
  }

  Widget _getRouterList() {
    return FutureBuilder(
      future: router.Router.find(),
      builder: (BuildContext context, AsyncSnapshot<router.Router> snapshot) {
        if (snapshot.hasError) {
          return Text('${snapshot.error} ${snapshot.stackTrace}');
        }
        if (!snapshot.hasData) {
          return const Text('Looking for router...');
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Router:',
            ),
            FutureBuilder(
                future: snapshot.requireData.getExternalIpAddress(),
                builder: (BuildContext context, AsyncSnapshot<String> data) =>
                    Text(data.hasData ? data.requireData : 'Loading...')),
            FutureBuilder(
                future: snapshot.requireData.getTotalBytesReceived(),
                builder: (BuildContext context, AsyncSnapshot<int> data) =>
                    Text(data.hasData ? 'Bytes Received: ${data.requireData}' : 'Loading...')),
            FutureBuilder(
                future: snapshot.requireData.getTotalBytesSent(),
                builder: (BuildContext context, AsyncSnapshot<int> data) =>
                    Text(data.hasData ? 'Bytes Sent: ${data.requireData}' : 'Loading...')),
            FutureBuilder(
                future: snapshot.requireData.getTotalPacketsReceived(),
                builder: (BuildContext context, AsyncSnapshot<int> data) =>
                    Text(data.hasData ? 'Packets Received: ${data.requireData}' : 'Loading...')),
            FutureBuilder(
                future: snapshot.requireData.getTotalPacketsSent(),
                builder: (BuildContext context, AsyncSnapshot<int> data) =>
                    Text(data.hasData ? 'Packets Sent: ${data.requireData}' : 'Loading...')),
          ],
        );
      },
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _getDevicesList();
      case 1:
        return _getRouterList();
    }
    return const Text("No idea");
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
