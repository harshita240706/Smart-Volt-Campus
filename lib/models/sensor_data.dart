class SensorData {
  final double temperature;
  final bool motionDetected;
  final bool smokeDetected;
  final String mode; // "auto" or "manual"
  final bool lightState;
  final bool fanState;

  SensorData({
    required this.temperature,
    required this.motionDetected,
    required this.smokeDetected,
    required this.mode,
    required this.lightState,
    required this.fanState,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temp'] ?? 0.0).toDouble(),
      motionDetected: json['motion'] ?? false,
      smokeDetected: json['smoke'] ?? false,
      mode: json['mode'] ?? 'auto',
      lightState: json['light'] == 'on',
      fanState: json['fan'] == 'on',
    );
  }

  factory SensorData.initial() {
    return SensorData(
      temperature: 0.0,
      motionDetected: false,
      smokeDetected: false,
      mode: 'auto',
      lightState: false,
      fanState: false,
    );
  }
}
