import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'ble_scanner.dart';
import 'device_list.dart';

final FlutterReactiveBle bleClient = new FlutterReactiveBle();
DiscoveredDevice heartRateMonitor;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final _ble = FlutterReactiveBle();
  final _scanner = BleScanner(_ble);
  runApp(
      MultiProvider(
        providers: [
          Provider.value(value: _scanner),
          // Provider.value(value: _monitor),
          // Provider.value(value: _connector),
          StreamProvider<BleScannerState>(
            create: (_) => _scanner.state,
            initialData: const BleScannerState(
              discoveredDevices: [],
              scanIsInProgress: false,
            ),
          ),
          // StreamProvider<BleStatus>(
          //   create: (_) => _monitor.state,
          //   initialData: BleStatus.unknown,
          // ),
          // StreamProvider<ConnectionStateUpdate>(
          //   create: (_) => _connector.state,
          //   initialData: const ConnectionStateUpdate(
          //     deviceId: 'Unknown device',
          //     connectionState: DeviceConnectionState.disconnected,
          //     failure: null,
          //   ),
          // ),
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
    print("Requesting permission: " + permission.toString());
    if (await permission.request().isGranted) {
      print("Permission granted: " + permission.toString());
    } else {
      print("Unable to get permission: " + permission.toString());
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
  Future warning;
  int _currentHeartRate = 0;
  int _maxHeartRate = 0;

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
      body: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _buildInfoColumn("Current heart rate", _currentHeartRate, Icons.favorite),
            _buildInfoColumn("Max heart rate", _maxHeartRate, Icons.whatshot),
          ],
        ),
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildInfoColumn(String label, int value, IconData icon) => Container(
    margin: const EdgeInsets.all(5),
    padding: const EdgeInsets.all(5) ,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value == 0 ? "N/A" : value.toString(),
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
    final device = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DeviceListScreen())
    );
    if (device == null) return;
    print("Received device: " + device.name);
    heartRateMonitor = device;
    final services = await bleClient.discoverServices(heartRateMonitor.id);
    services.forEach((service) {
      print("Service: " + service.toString());
      service.characteristicIds.forEach((char) {
        print("---- " + char.toString());
      });
    });
  }
}