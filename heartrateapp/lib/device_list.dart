import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import 'ble_scanner.dart';

final Uuid _heartRateService = new Uuid.parse("0000180d-0000-1000-8000-00805f9b34fb"); 

class DeviceListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer2<BleScanner, BleScannerState>(
      builder: (_, bleScanner, bleScannerState, __) =>
          _DeviceList(
            scannerState: bleScannerState,
            startScan: bleScanner.startScan,
            stopScan: bleScanner.stopScan,
          ),
    );
}

  class _DeviceList extends StatefulWidget {
    const _DeviceList(
    {@required this.scannerState,
    @required this.startScan,
    @required this.stopScan})
        : assert(scannerState != null),
    assert(startScan != null),
    assert(stopScan != null);

    final BleScannerState scannerState;
    final void Function(List<Uuid>) startScan;
    final VoidCallback stopScan;

    @override
    _DeviceListState createState() => _DeviceListState();
  }

class _DeviceListState extends State<_DeviceList> {
  TextEditingController _uuidController;

  @override
  void initState() {
    super.initState();
    _uuidController = TextEditingController()
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.stopScan();
    _uuidController.dispose();
    super.dispose();
  }

  void _startScanning(Uuid uuid) {
    widget.startScan([uuid]);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.scannerState.scanIsInProgress) _startScanning(_heartRateService);
    return Scaffold(
      body: ListView(
        children: widget.scannerState.discoveredDevices.map((device) => ListTile(
          title: Text(
            device.name.isEmpty ? "N/A" : device.name,
            style: device.name.isEmpty ? TextStyle(fontWeight: FontWeight.w200) :
                TextStyle(fontWeight: FontWeight.normal)
          ),
          subtitle: Wrap(
            spacing: 5,
            children: <Widget>[
              Text("${device.id}"),
              Text("RSSI: ${device.rssi}")
            ],
          ),
          leading: Icon(Icons.phone_bluetooth_speaker),
          onTap: () async {
            widget.stopScan();
            Navigator.pop(context, device);
          },
        )).toList(),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
          widget.stopScan();
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

  Widget _buildRow(DiscoveredDevice device) {
    return ListTile(
      title: Text(
        device.name.isEmpty ? "N/A" : device.name
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
        Navigator.pop(context, device);
      },
    );
  }
}