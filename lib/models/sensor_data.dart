class SensorData {
  final double temperature;
  final double humidity;
  final bool motionDetected;
  final bool smokeDetected;
  final String mode; // "auto" or "manual"
  final bool lightState;
  final double energyConsumed;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.motionDetected,
    required this.smokeDetected,
    required this.mode,
    required this.lightState,
    required this.energyConsumed,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temp'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      motionDetected: json['motion'] ?? false,
      smokeDetected: json['smoke'] ?? false,
      mode: json['mode'] ?? 'auto',
      lightState: json['light'] == 'on',
      energyConsumed: (json['energy'] ?? 0.0).toDouble(),
    );
  }

  factory SensorData.fromThingSpeak(Map<String, dynamic> json) {
    return SensorData(
      temperature: double.tryParse(json['field1'] ?? '0.0') ?? 0.0,
      humidity: double.tryParse(json['field2'] ?? '0.0') ?? 0.0,
      motionDetected: (json['field3'] ?? '0') == '1',
      smokeDetected: (json['field4'] ?? '0') == '1',
      mode: (json['field5'] ?? '0') == '0' ? 'auto' : 'manual',
      lightState: (json['field6'] ?? '0') == '1',
      energyConsumed: double.tryParse(json['field8'] ?? '0.0') ?? 0.0,
    );
  }

  factory SensorData.initial() {
    return SensorData(
      temperature: 0.0,
      humidity: 0.0,
      motionDetected: false,
      smokeDetected: false,
      mode: 'auto',
      lightState: false,
      energyConsumed: 0.0,
    );
  }
}
