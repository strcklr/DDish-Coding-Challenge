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
import 'device_detail.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterReactiveBle _ble = FlutterReactiveBle();
  BleScanner _scanner = BleScanner(_ble);
  BleDeviceConnector _connector = BleDeviceConnector(_ble);
  BleStatusMonitor _monitor = BleStatusMonitor(_ble);

  runApp(
      MultiProvider(
        providers: [
          Provider.value(value: _scanner),
          Provider.value(value: _monitor),
          Provider.value(value: _connector),
          Provider.value(value: _ble),
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
  final Uuid hrService = Uuid.parse("0000180d-0000-1000-8000-00805f9b34fb");
  final Map<int, int> _heartRateHistory = new Map();
  DiscoveredDevice heartRateMonitor;
  ConnectionStateUpdate connectionStateUpdate;
  DeviceDetail _deviceDetail;
  Future warning;
  int _maxHeartRate = 0;
  int _currentHeartRate = 0;

  @override
  void initState() {
    super.initState();
  }

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
                "N/A" : "$_maxHeartRate", Icons.whatshot),
            ],
          ),
          Container(
            // TODO Add graph of workout HB history
          ),
          Consumer3<FlutterReactiveBle, BleDeviceConnector, ConnectionStateUpdate>(
              builder: (_, ble, connector, connectionStateUpdate, __) =>
              _deviceDetail = _buildDeviceDetail(ble, connector, connectionStateUpdate, heartRateMonitor)
          )
        ],
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
            // TODO Begin or stop workout
            print("Workout started!");
            fabKey.currentState.close();
          })
        ]
      ),
    );
  }

  Widget _buildDeviceDetail(FlutterReactiveBle ble, BleDeviceConnector connector, ConnectionStateUpdate connectionStateUpdate, DiscoveredDevice device) => DeviceDetail(
    device: device,
    connectionUpdate: connectionStateUpdate != null &&
    connectionStateUpdate.deviceId == device?.id
      ? connectionStateUpdate
          : ConnectionStateUpdate(
      deviceId: device?.id,
      connectionState: DeviceConnectionState.disconnected,
      failure: null,
    ),
    connect: connector.connect,
    disconnect: connector.disconnect,
    discoverServices: connector.discoverServices,
    subscribe: ble.subscribeToCharacteristic,
    readCharacteristic: ble.readCharacteristic,
  );

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

  void showAlert(String title, String message) {
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
  }

  void checkHeartRate() {
    if ((_currentHeartRate > _maxHeartRate) &&
        (_maxHeartRate != 0) &&
        (warning == null)) {
      print("Current heart rate exceeds maximum!");
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        showAlert("Warning!", "You've exceeded your maximum heart rate! Consider slowing down.");
      });
    }
  }

  void connectToDevice() async {
    Uuid current = Uuid.parse("00002a37-0000-1000-8000-00805f9b34fb");
    QualifiedCharacteristic currentCharacteristic = QualifiedCharacteristic(
        characteristicId: current,
        serviceId: hrService,
        deviceId: heartRateMonitor.id
    );

    _deviceDetail.connect(heartRateMonitor.id).whenComplete(() =>
        Future.delayed(Duration(seconds: 5), () =>
            _deviceDetail.discoverServices(heartRateMonitor.id).whenComplete(() async {
              // Subscribe to Current Heart Rate Characteristic
              _deviceDetail.subscribe(currentCharacteristic).listen((data) {
                print("Received current data $data");
                setState(() {
                  _currentHeartRate = data[1];
                });
              }, onError: (error) => print("Error listening to charac $error"));
            }
          ),
        )
    );
  }

  void startBluetoothScan() async {
    heartRateMonitor = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DeviceListScreen())
    );
    if (heartRateMonitor == null) return;
    print("Received device: " + heartRateMonitor.name);
    setState(() {
      connectToDevice();
    });
  }
}