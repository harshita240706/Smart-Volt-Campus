import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class EspService {
  String baseUrl = "http://192.168.1.50"; // Default IP

  void updateBaseUrl(String ip) {
    if (ip.startsWith('http')) {
      baseUrl = ip;
    } else {
      baseUrl = "http://$ip";
    }
  }

  Future<SensorData?> fetchStatus() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/status")).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        return SensorData.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("Error fetching status: $e");
    }
    return null;
  }

  Future<bool> setMode(String mode) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/setMode?val=$mode"));
      return response.statusCode == 200;
    } catch (e) {
      print("Error setting mode: $e");
      return false;
    }
  }

  Future<bool> controlDevice(String device, bool state) async {
    try {
      final stateStr = state ? "on" : "off";
      final response = await http.get(Uri.parse("$baseUrl/control?device=$device&state=$stateStr"));
      return response.statusCode == 200;
    } catch (e) {
      print("Error controlling device: $e");
      return false;
    }
  }
}
