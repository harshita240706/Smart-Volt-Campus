import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryProvider with ChangeNotifier {
  static const String _historyKey = "energyHistory";
  
  // Stores energy saved in kWh (simulation)
  Map<String, double> _weeklyData = {
    "Monday": 0.0,
    "Tuesday": 0.0,
    "Wednesday": 0.0,
    "Thursday": 0.0,
    "Friday": 0.0,
    "Saturday": 0.0,
  };

  Map<String, double> get weeklyData => _weeklyData;

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_historyKey);
    if (savedData != null) {
      final Map<String, dynamic> decoded = jsonDecode(savedData);
      _weeklyData = decoded.map((key, value) => MapEntry(key, value.toDouble()));
      notifyListeners();
    }
  }

  Future<void> updateEnergy(String day, double value) async {
    if (_weeklyData.containsKey(day)) {
      _weeklyData[day] = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(_weeklyData));
      notifyListeners();
    }
  }

  // Helper for simulation - adds a small amount to current day
  Future<void> addSimulationData() async {
    // For demo purposes, we'll just update Monday for now or use current weekday
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    final now = DateTime.now();
    // Monday is 1, Saturday is 6 in DateTime.weekday
    if (now.weekday >= 1 && now.weekday <= 6) {
      final dayName = days[now.weekday - 1];
      _weeklyData[dayName] = (_weeklyData[dayName] ?? 0) + 0.1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(_weeklyData));
      notifyListeners();
    }
  }
}
