import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/* isLeEnabled gets triggered repeatedly, looking for a way to instantiate this
such that it isn't recreated every time the widget is built. */
final bleClient = new FlutterReactiveBle();

class ScanRoute extends StatelessWidget {
  /* TODO need to request location/bluetooth permissions */
  @override
  Widget build(BuildContext context) {
    return ScanPage(
    );
  }
}

class ScanPage extends StatefulWidget {
  ScanPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _devices = new List<DiscoveredDevice>();
  @override
  Widget build(BuildContext context) {
    /* TODO Add services to filter on */
    final _scanStream = bleClient.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
      if (device.name.isEmpty) return;
      if (!isDuplicate(device)) {
        setState(() {
          _devices.add(device);
        });
      }
    }, onError: (error) {});
    return Scaffold(
      body: _displayDiscoveredDevices(),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
          _scanStream.cancel();
          _devices.clear();
          bleClient.deinitialize();
          Navigator.pop(context);
        },
        backgroundColor: ThemeData.dark().bottomAppBarColor,
        child: new Icon(
          Icons.arrow_back,
          color: Colors.blue,
        ),
      ),
    );
  }

  bool isDuplicate(DiscoveredDevice device) {
    return (_devices.contains(device) || (_devices.any((e) => (e.id == device.id))));
  }

  Widget _displayDiscoveredDevices() {
    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, i) {
        if (i.isOdd) return Divider(
          color: Colors.grey,
        );
        return _buildRow(_devices.elementAt(i));
      }
    );
  }

  Widget _buildRow(DiscoveredDevice device) {
    return ListTile(
      title: Text(
        device.name
      ),
      subtitle: Wrap(
        spacing: 15,
        children: <Widget>[
          Text(
            device.id
          ),
          Text(
            "RSSI: " + device.rssi.toString()
          )
        ],
      ),
      leading: new Icon(
        Icons.phone_bluetooth_speaker
      ),
      onTap: () {
        /* TODO handle device selection */
      },
    );
  }
}