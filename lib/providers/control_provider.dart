import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/esp_service.dart';

class ControlProvider with ChangeNotifier {
  final EspService _espService = EspService();
  SensorData _data = SensorData.initial();
  bool _isConnected = false;
  Timer? _pollingTimer;

  SensorData get data => _data;
  bool get isConnected => _isConnected;
  String get currentIp => _espService.baseUrl.replaceFirst("http://", "");

  ControlProvider() {
    startPolling();
  }

  void updateIp(String ip) {
    _espService.updateBaseUrl(ip);
    notifyListeners();
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final newData = await _espService.fetchStatus();
      if (newData != null) {
        _data = newData;
        _isConnected = true;
      } else {
        _isConnected = false;
      }
      notifyListeners();
    });
  }

  Future<void> toggleMode() async {
    final newMode = _data.mode == "auto" ? "manual" : "auto";
    final success = await _espService.setMode(newMode);
    if (success) {
      // Optimistic update or wait for next poll
      _data = SensorData(
        temperature: _data.temperature,
        motionDetected: _data.motionDetected,
        smokeDetected: _data.smokeDetected,
        mode: newMode,
        lightState: _data.lightState,
        fanState: _data.fanState,
      );
      notifyListeners();
    }
  }

  Future<void> controlDevice(String device, bool state) async {
    if (_data.mode != "manual") return;
    
    final success = await _espService.controlDevice(device, state);
    if (success) {
      _data = SensorData(
        temperature: _data.temperature,
        motionDetected: _data.motionDetected,
        smokeDetected: _data.smokeDetected,
        mode: _data.mode,
        lightState: device == "light" ? state : _data.lightState,
        fanState: device == "fan" ? state : _data.fanState,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
