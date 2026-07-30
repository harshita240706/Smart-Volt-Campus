import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';
import '../services/esp_service.dart';
import '../services/thing_speak_service.dart';

class ControlProvider with ChangeNotifier {
  final EspService _espService = EspService();
  ThingSpeakService? _thingSpeakService;
  
  SensorData _data = SensorData.initial();
  bool _isConnected = false;
  Timer? _pollingTimer;

  bool _isCloudMode = false;
  String _channelId = "";
  String _readKey = "";
  String _writeKey = "";

  SensorData get data => _data;
  bool get isConnected => _isConnected;
  bool get isCloudMode => _isCloudMode;
  String get currentIp => _espService.baseUrl.replaceFirst("http://", "");
  String get channelId => _channelId;
  String get readKey => _readKey;
  String get writeKey => _writeKey;

  ControlProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isCloudMode = prefs.getBool('cloudMode') ?? false;
    _channelId = prefs.getString('channelId') ?? "";
    _readKey = prefs.getString('readKey') ?? "";
    _writeKey = prefs.getString('writeKey') ?? "";
    
    final savedIp = prefs.getString('espIp') ?? "192.168.1.50";
    _espService.updateBaseUrl(savedIp);

    _initThingSpeak();
    startPolling();
  }

  void _initThingSpeak() {
    if (_channelId.isNotEmpty && _readKey.isNotEmpty && _writeKey.isNotEmpty) {
      _thingSpeakService = ThingSpeakService(
        channelId: _channelId,
        readKey: _readKey,
        writeKey: _writeKey,
      );
    } else {
      _thingSpeakService = null;
    }
  }

  Future<void> updateIp(String ip) async {
    _espService.updateBaseUrl(ip);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('espIp', ip);
    notifyListeners();
  }

  Future<void> updateThingSpeakSettings({
    required String channelId,
    required String readKey,
    required String writeKey,
  }) async {
    _channelId = channelId;
    _readKey = readKey;
    _writeKey = writeKey;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('channelId', channelId);
    await prefs.setString('readKey', readKey);
    await prefs.setString('writeKey', writeKey);
    
    _initThingSpeak();
    startPolling(); // Restart polling with new settings
    notifyListeners();
  }

  Future<void> toggleCloudMode(bool value) async {
    _isCloudMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cloudMode', value);
    startPolling(); // Restart polling with new interval
    notifyListeners();
  }

  void startPolling() {
    _pollingTimer?.cancel();
    final interval = _isCloudMode ? const Duration(seconds: 20) : const Duration(seconds: 2);
    
    _pollingTimer = Timer.periodic(interval, (timer) async {
      SensorData? newData;
      if (_isCloudMode) {
        if (_thingSpeakService != null) {
          newData = await _thingSpeakService!.fetchLatestFeed();
        }
      } else {
        newData = await _espService.fetchStatus();
      }

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
    bool success = false;
    
    if (_isCloudMode && _thingSpeakService != null) {
      success = await _thingSpeakService!.updateField(5, newMode == "manual" ? "1" : "0");
    } else {
      success = await _espService.setMode(newMode);
    }

    if (success) {
      _data = SensorData(
        temperature: _data.temperature,
        humidity: _data.humidity,
        motionDetected: _data.motionDetected,
        smokeDetected: _data.smokeDetected,
        mode: newMode,
        lightState: _data.lightState,
        energyConsumed: _data.energyConsumed,
      );
      notifyListeners();
    }
  }

  Future<void> controlDevice(String device, bool state) async {
    if (_data.mode != "manual") return;
    
    bool success = false;
    if (_isCloudMode && _thingSpeakService != null) {
      if (device == "light") {
        success = await _thingSpeakService!.updateField(6, state ? "1" : "0");
      }
    } else {
      success = await _espService.controlDevice(device, state);
    }

    if (success) {
      _data = SensorData(
        temperature: _data.temperature,
        humidity: _data.humidity,
        motionDetected: _data.motionDetected,
        smokeDetected: _data.smokeDetected,
        mode: _data.mode,
        lightState: device == "light" ? state : _data.lightState,
        energyConsumed: _data.energyConsumed,
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
