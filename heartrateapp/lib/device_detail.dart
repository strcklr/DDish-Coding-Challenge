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
    @required this.readCharacteristic,
    Key key,
  });

  final DiscoveredDevice device;
  final ConnectionStateUpdate connectionUpdate;
  final Future<void> Function(String deviceId) connect;
  final void Function(String deviceId) disconnect;
  final Future<void> Function(String deviceId) discoverServices;
  final Stream<List<int>> Function(QualifiedCharacteristic characteristic) subscribe;
  final Future<List<int>> Function(QualifiedCharacteristic characteristic) readCharacteristic;

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
        _buildDeviceRow("${widget.device?.name} | ${widget.connectionUpdate?.connectionState.toString() ?? "N/A"}"),
      ];
    }
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