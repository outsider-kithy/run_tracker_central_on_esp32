
class RunningData {
  final List<Point> points;
  final double distance;
  final int steps;
  final int elapsedSeconds;
  final String startDate;
  final String endDate;
  final double temp;
  final double avgBpm;

  RunningData({
    required this.points,
    required this.distance,
    required this.steps,
    required this.elapsedSeconds,
    required this.startDate,
    required this.endDate,
    required this.temp,
    required this.avgBpm
  });

  factory RunningData.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>;
    final points = pointsJson.map((p) => Point.fromJson(p)).toList();

    return RunningData(
      points: points,
      distance: (json['distance'] as num).toDouble(),
      steps: json['steps'] as int,
      elapsedSeconds: json['elapsedSeconds'] as int,
      startDate:  json['startDate'] as String,
      endDate:  json['endDate'] as String,
      temp: (json['Temp'] as num).toDouble(),
      avgBpm: (json['Avg BPM'] as num).toDouble()
    );
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'distance': distance,
    'steps': steps,
    'elapsedSeconds': elapsedSeconds,
    'startDate': startDate,
    'endDate': endDate,
    'temp': temp,
    'avgBpm': avgBpm,
  };
}

class Point {
  final double lat;
  final double lng;

  Point({required this.lat, required this.lng});

  factory Point.fromJson(Map<String, dynamic> json) => Point(
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
  };
}
