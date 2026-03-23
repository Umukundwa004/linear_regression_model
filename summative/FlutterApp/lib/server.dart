import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

/// =============================
/// 🚴 Bike Prediction Logic
/// =============================

// Replace this with real model later
int predictBikeRentals(List<double> features) {
  // Simple mock logic (simulate ML model)
  double score = features.reduce((a, b) => a + b);

  if (score < 100) return 100;
  if (score < 200) return 250;
  if (score < 300) return 450;
  return 650;
}

/// =============================
/// 🌿 Season calculation
/// =============================
int getSeason(int month) {
  if ([3, 4, 5].contains(month)) return 1; // Spring
  if ([6, 7, 8].contains(month)) return 2; // Summer
  if ([9, 10, 11].contains(month)) return 3; // Fall
  return 4; // Winter
}

/// =============================
/// 🚀 MAIN SERVER
/// =============================
void main() async {
  final router = Router();

  /// Root endpoint
  router.get('/', (Request req) {
    return Response.ok(
      jsonEncode({"message": "🚴 Bike Rental API running"}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  /// Prediction endpoint
  router.post('/predict', (Request req) async {
    try {
      final body = await req.readAsString();
      final data = jsonDecode(body);

      /// =============================
      /// 📥 Extract Inputs (from Flutter)
      /// =============================
      final date = DateTime.parse(data['date']);
      final hour = data['hour'];
      final temp = data['temp']; // °C
      final humidity = data['humidity']; // %
      final windspeed = data['windspeed']; // km/h
      final weather = data['weather']; // 1–4
      final holiday = data['holiday']; // 0/1

      /// =============================
      /// ⚙️ Feature Engineering
      /// =============================
      final weekday = date.weekday - 1; // 0–6
      final workingday = weekday < 5 ? 1 : 0;
      final month = date.month;
      final year = date.year - 2011;
      final season = getSeason(month);

      /// =============================
      /// 📊 Feature Vector (IMPORTANT ORDER)
      /// =============================
      List<double> features = [
        season.toDouble(),
        year.toDouble(),
        month.toDouble(),
        hour.toDouble(),
        holiday.toDouble(),
        weekday.toDouble(),
        workingday.toDouble(),
        weather.toDouble(),
        temp.toDouble(),
        humidity.toDouble(),
        windspeed.toDouble(),
      ];

      /// =============================
      /// 🤖 Prediction
      /// =============================
      final prediction = predictBikeRentals(features);

      /// Optional insights (like your student app)
      List<String> insights = [];

      if (temp > 30) insights.add("🔥 Hot weather may reduce demand");
      if (weather == 3 || weather == 4)
        insights.add("🌧 Rain reduces bike usage");
      if (hour >= 7 && hour <= 9) insights.add("🚶 Morning commute peak");
      if (hour >= 17 && hour <= 19) insights.add("🚴 Evening peak hours");

      /// =============================
      /// 📤 Response
      /// =============================
      return Response.ok(
        jsonEncode({
          "predicted_rentals": prediction,
          "confidence": 0.87,
          "insights": insights,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          "error": e.toString(),
          "message": "Failed to process prediction",
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  /// Middleware
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, 'localhost', 8005);

  print('🚀 Server running at http://${server.address.host}:${server.port}');
}
