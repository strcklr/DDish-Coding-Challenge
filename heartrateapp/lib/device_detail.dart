import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DeviceDetail extends StatefulWidget {
  DeviceDetail({
    @required this.device,
    @required this.connectionUpdate,
    @required this.connect,
    @required this.disconnect,
    @required this.discoverServices,
    @required this.subscribe,
    Key key,
  });

  final DiscoveredDevice device;
  final ConnectionStateUpdate connectionUpdate;
  final Future<void> Function(String deviceId) connect;
  final void Function(String deviceId) disconnect;
  final Future<void> Function(String deviceId) discoverServices;
  final Stream<List<int>> Function(QualifiedCharacteristic characteristic) subscribe;

  @override
  State<StatefulWidget> createState() => _DeviceDetailState();
}

class _DeviceDetailState extends State<DeviceDetail> {

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: _buildDevice()
    );
  }

  List<Widget> _buildDevice() {
    if (widget.device == null) {
      return [_buildDeviceRow("")];
    } else {
      return [
        _buildDeviceRow("HR Monitor: ${widget.device?.name}"),
        _buildDeviceRow(
            "Status | ${widget.connectionUpdate?.connectionState ?? "N/A"}")
      ];
    }
  }

  Widget _buildDeviceRow(String text) {
    print("Building device row with text: $text, device: ${widget.device?.name}");
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