import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:heartrateapp/ble/reactive_state.dart';

/// Created by following the example project provided by flutter_reactive_ble
/// GitHub: https://github.com/PhilipsHue/flutter_reactive_ble/tree/master/example/lib/src
/// pub.dev: https://pub.dev/packages/flutter_reactive_ble
class BleDeviceConnector extends ReactiveState<ConnectionStateUpdate> {
  BleDeviceConnector(this._ble);

  final FlutterReactiveBle _ble;

  @override
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;

  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();

  StreamSubscription<ConnectionStateUpdate> _connection;

  Future<void> connect(String deviceId) async {
    if (_connection != null) {
      await _connection.cancel();
    }
    _connection = _ble.connectToDevice(
        id: deviceId,
        // ConnectionTimeout is essential as it sets autoConnect to false
        connectionTimeout: const Duration(seconds: 10)).listen(
      _deviceConnectionController.add,
    );
  }

  Future<void> disconnect(String deviceId) async {
    if (_connection != null) {
      try {
        await _connection.cancel();
      } on Exception catch (e, _) {
        print("Error disconnecting from a device: $e");
      } finally {
        // Since [_connection] subscription is terminated, the "disconnected" state cannot be received and propagated
        _deviceConnectionController.add(
          ConnectionStateUpdate(
            deviceId: deviceId,
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        );
      }
    }
  }

  Future<void> discoverServices(String deviceId) async {
    await _ble.discoverServices(deviceId).then(
          (services) =>
          {
            services.forEach((service) {
              print("Service: ${service.toString()}");
              service.characteristicIds.forEach((characteristic) {
                print("---- ${characteristic.toString()}");
              });
            })
        });
  }

  Future<void> dispose() async {
    await _deviceConnectionController.close();
  }
}