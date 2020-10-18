import 'dart:ui';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:heartrateapp/ble/ble_connector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'ble/ble_scanner.dart';
import 'device_list.dart';

// TODO Determine if leaving these objects here is best practice or not? Feels wrong
DiscoveredDevice heartRateMonitor;
FlutterReactiveBle _ble = FlutterReactiveBle();
BleScanner _scanner = BleScanner(_ble);
BleDeviceConnector _connector = BleDeviceConnector(_ble);
BleStatusMonitor _monitor = BleStatusMonitor(_ble);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
      MultiProvider(
        providers: [
          Provider.value(value: _scanner),
          Provider.value(value: _monitor),
          Provider.value(value: _connector),
          StreamProvider<BleScannerState>(
            create: (_) => _scanner.state,
            initialData: const BleScannerState(
              discoveredDevices: [],
              scanIsInProgress: false,
            ),
          ),
          StreamProvider<BleStatus>(
            create: (_) => _monitor.state,
            initialData: BleStatus.unknown,
          ),
          StreamProvider<ConnectionStateUpdate>(
            create: (_) => _connector.state,
            initialData: const ConnectionStateUpdate(
              deviceId: 'Unknown device',
              connectionState: DeviceConnectionState.disconnected,
              failure: null,
            ),
          ),
        ],
        child: HomeRoute()
      ),
  );
}

class HomeRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    requestPerm(Permission.locationWhenInUse);
    return MaterialApp(
      title: 'Heart Rate Tracker',
      theme: ThemeData.dark(),
      home: HomePage(title: 'Heart Rate Tracker'),
    );
  }

  void requestPerm(Permission permission) async {
    print("Requesting permission: $permission");
    if (await permission.request().isGranted) {
      print("Permission granted");
    } else {
      print("Permission Denied:");
    }
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<FabCircularMenuState> fabKey = GlobalKey();
  final maxHeartRateController = TextEditingController();
  ConnectionStateUpdate connectionStateUpdate;
  Future warning;
  int _maxHeartRate = 0;
  int _currentHeartRate = 0;

  @override
  void dispose() {
    maxHeartRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    checkHeartRate();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildInfoColumn("Current heart rate", _currentHeartRate == 0 ?
                "N/A" : "$_currentHeartRate", Icons.favorite),
              _buildInfoColumn("Max heart rate", _maxHeartRate == 0 ?
                "N/A" : _maxHeartRate, Icons.whatshot),
            ],
          ),
          Container(
            // TODO Add graph of workout HB history
          ),
          Consumer2<BleDeviceConnector, ConnectionStateUpdate>(
            builder: (_, connector, connectionStateUpdate, __) =>
                _DeviceDetail(
                  device: heartRateMonitor,
                  connectionUpdate: connectionStateUpdate != null &&
                      connectionStateUpdate.deviceId == heartRateMonitor?.id
                      ? connectionStateUpdate
                      : ConnectionStateUpdate(
                    deviceId: heartRateMonitor?.id,
                    connectionState: DeviceConnectionState.disconnected,
                    failure: null,
                  ),
                  connect: _connector.connect,
                  disconnect: _connector.disconnect,
                  discoverServices: _connector.discoverServices,
                ),
          ),
        ]
      ),
      floatingActionButton: FabCircularMenu(
        key: fabKey,
        ringDiameter: 500,
        ringColor: ThemeData.dark().bottomAppBarColor,
        fabColor: Colors.blueAccent,
        children: <Widget>[
          _buildMenuItem("Bluetooth Scan", Icons.bluetooth, () {
            fabKey.currentState.close();
            startBluetoothScan();
          }),
          _buildMenuItem("Set Max Heart Rate", Icons.whatshot, () {
            return showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  contentPadding: const EdgeInsets.all(15.0),
                  content: new TextField(
                    controller: maxHeartRateController,
                    autofocus: true,
                    maxLength: 3, /* Heart rate is 3 digit max */
                    keyboardType: TextInputType.number,
                    decoration: new InputDecoration(
                      hintText: "Max Heart Rate",
                    ),
                  ),
                  actions: <Widget>[
                    new FlatButton(
                      child: const Text('CANCEL'),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                    new FlatButton(
                      child: const Text('SET'),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _maxHeartRate = int.parse(maxHeartRateController.text);
                        });
                      })
                  ],
                );
              }
            );
          }),
          _buildMenuItem("Start Workout", Icons.directions_run, () {
            /* TODO Begin workout */
            print("Workout started!");
            fabKey.currentState.close();
          })
        ]
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) => Container(
    margin: const EdgeInsets.all(5),
    padding: const EdgeInsets.all(5) ,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(
              label,
            ),
          ],
        ),
        Icon(
            icon,
            color: Colors.redAccent
        ),
      ],
    )
  );

  Widget _buildMenuItem(String label, IconData icon, VoidCallback pressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          splashRadius: 20,
          onPressed: pressed,
          icon: new Icon(
            icon,
            color: Colors.redAccent
          )
        ),
        Text(label),
      ],
    );
  }

  void checkHeartRate() {
    if ((_currentHeartRate > _maxHeartRate) &&
        (_maxHeartRate != 0) &&
        (warning == null)) {
      print("Current heart rate exceeds maximum!");
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        warning = showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                contentPadding: const EdgeInsets.all(15.0),
                title: Text("Warning!"),
                content: Text("You've exceeded your maximum heart rate! Consider "
                    "slowing down."),
                actions: <Widget>[
                  new FlatButton(
                    child: const Text('Ok'),
                    onPressed: () {
                      Navigator.pop(context);
                      warning = null;
                    })
                ],
              );
            }
        );
      });
    }
  }

  void startBluetoothScan() async {
    heartRateMonitor = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DeviceListScreen())
    );
    if (heartRateMonitor == null) return;
    print("Received device: " + heartRateMonitor.name);
    await _connector.connect(heartRateMonitor.id);

    /* Android BLE needs some time after connecting before entering discovery phase */
    Future.delayed(Duration(seconds: 3), () {
      _connector.discoverServices(heartRateMonitor.id).whenComplete(() =>
          print("Services discovered!"));
    });
    setState(() {});
  }
}

class _DeviceDetail extends StatelessWidget {
  const _DeviceDetail({
    @required this.device,
    @required this.connectionUpdate,
    @required this.connect,
    @required this.disconnect,
    @required this.discoverServices,
    Key key,
  })  : assert(connect != null),
        assert(disconnect != null),
        assert(discoverServices != null),
        super(key: key);

  final DiscoveredDevice device;
  final ConnectionStateUpdate connectionUpdate;
  final void Function(String deviceId) connect;
  final void Function(String deviceId) disconnect;
  final void Function(String deviceId) discoverServices;

  bool _deviceConnected() =>
      connectionUpdate.connectionState == DeviceConnectionState.connected;

  @override
  Widget build(BuildContext context) {
    if (device == null) {
      return _buildDeviceRow("No device connected!");
    } else if (!_deviceConnected()) {
      connect(device.id);
    }
    return Wrap(
      children: <Widget>[
        _buildDeviceRow("HR Monitor: ${device?.name}"),
        _buildDeviceRow("Status | ${connectionUpdate.connectionState ?? "N/A"}")
      ],
    );
  }
  
  Widget _buildDeviceRow(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w100,
              fontStyle: FontStyle.italic,
            ),
          )
        ],
      ),
    );
  }


}