import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:heartrateapp/ble/reactive_state.dart';

/// Created by following the example project provided by flutter_reactive_ble
/// GitHub: https://github.com/PhilipsHue/flutter_reactive_ble/tree/master/example/lib/src
/// pub.dev: https://pub.dev/packages/flutter_reactive_ble
class BleStatusMonitor implements ReactiveState<BleStatus> {
  const BleStatusMonitor(this._ble);

  final FlutterReactiveBle _ble;

  @override
  Stream<BleStatus> get state => _ble.statusStream;
}