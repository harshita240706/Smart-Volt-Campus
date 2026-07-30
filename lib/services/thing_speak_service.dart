import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ThingSpeakService {
  final String channelId;
  final String readKey;
  final String writeKey;

  ThingSpeakService({
    required this.channelId,
    required this.readKey,
    required this.writeKey,
  });

  String get baseUrl => "https://api.thingspeak.com";

  Future<SensorData?> fetchLatestFeed() async {
    try {
      final url = "$baseUrl/channels/$channelId/feeds/last.json?api_key=$readKey";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null || data == -1 || (data is Map && data.isEmpty)) {
          print("ThingSpeak: Channel is empty or no data found.");
          return null;
        }
        return SensorData.fromThingSpeak(data);
      } else if (response.statusCode == 404) {
        print("ThingSpeak Error: Channel ID not found.");
      } else if (response.statusCode == 403) {
        print("ThingSpeak Error: Invalid API Key.");
      } else {
        print("ThingSpeak Error: Status ${response.statusCode}");
      }
    } catch (e) {
      print("ThingSpeak Exception: $e");
    }
    return null;
  }

  Future<bool> updateField(int fieldIndex, String value) async {
    try {
      final url = "$baseUrl/update?api_key=$writeKey&field$fieldIndex=$value";
      final response = await http.get(Uri.parse(url));
      // ThingSpeak returns the entry ID (an integer) on success, or 0 on failure
      return response.statusCode == 200 && response.body != "0";
    } catch (e) {
      print("Error updating ThingSpeak field: $e");
      return false;
    }
  }

  Future<bool> updateMultipleFields(Map<int, String> fields) async {
    try {
      String query = "api_key=$writeKey";
      fields.forEach((index, value) {
        query += "&field$index=$value";
      });
      final url = "$baseUrl/update?$query";
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200 && response.body != "0";
    } catch (e) {
      print("Error updating multiple ThingSpeak fields: $e");
      return false;
    }
  }
}
