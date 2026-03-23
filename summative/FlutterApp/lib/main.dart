import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const BikeApp());
}

class BikeApp extends StatelessWidget {
  const BikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const BikePredictionPage(),
    );
  }
}

class BikePredictionPage extends StatefulWidget {
  const BikePredictionPage({super.key});

  @override
  State<BikePredictionPage> createState() => _BikePredictionPageState();
}

class PredictionPage extends BikePredictionPage {
  const PredictionPage({super.key});
}

class _BikePredictionPageState extends State<BikePredictionPage> {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://localhost:8005' : 'http://10.0.2.2:8005',
  );

  DateTime selectedDate = DateTime.now();
  int hour = 12;
  int season = 1;
  int weather = 1;
  bool holiday = false;

  final tempController = TextEditingController();
  final humController = TextEditingController();
  final windController = TextEditingController();

  String result = "";
  bool isLoading = false;

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Widget buildCard({required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildInput(
    String label,
    IconData icon,
    TextEditingController controller,
    String unit,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue),
        suffixText: unit,
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> predict() async {
    if (tempController.text.isEmpty ||
        humController.text.isEmpty ||
        windController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
    });

    try {
      final temp = double.tryParse(tempController.text);
      final hum = double.tryParse(humController.text);
      final wind = double.tryParse(windController.text);
      if (temp == null || hum == null || wind == null) {
        throw const FormatException('Please enter valid numeric values.');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/predict'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "date": selectedDate.toIso8601String().split('T')[0],
          "hour": hour,
          "holiday": holiday ? 1 : 0,
          "weather": weather,
          "temp": temp,
          "humidity": hum,
          "windspeed": wind,
        }),
      );

      if (response.statusCode != 200) {
        final err = response.body.isNotEmpty ? response.body : 'Server error';
        throw Exception("${response.statusCode}: $err");
      }

      final data = jsonDecode(response.body);
      if (!mounted) {
        return;
      }
      setState(() {
        result = "🚴 ${data['predicted_rentals']} rentals";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Prediction successful ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        result = "❌ Connection failed";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}", maxLines: 2),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bike Predictor"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 📅 DATE
            buildCard(
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "${selectedDate.toLocal()}".split(' ')[0],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(onPressed: pickDate, child: Text("Change")),
                ],
              ),
            ),

            // ⏰ HOUR
            buildCard(
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange),
                  SizedBox(width: 20),
                  Expanded(
                    child: DropdownButton<int>(
                      value: hour,
                      isExpanded: true,
                      isDense: true,
                      underline: SizedBox(),
                      items: List.generate(
                        24,
                        (i) =>
                            DropdownMenuItem(value: i, child: Text("Hour $i")),
                      ),
                      onChanged: (v) => setState(() => hour = v!),
                    ),
                  ),
                ],
              ),
            ),

            // 🍃 SEASON
            buildCard(
              child: Row(
                children: [
                  Icon(Icons.park, color: Colors.green),
                  SizedBox(width: 20),
                  Expanded(
                    child: DropdownButton<int>(
                      value: season,
                      isExpanded: true,
                      isDense: true,
                      underline: SizedBox(),
                      items: [
                        DropdownMenuItem(value: 1, child: Text("Spring")),
                        DropdownMenuItem(value: 2, child: Text("Summer")),
                        DropdownMenuItem(value: 3, child: Text("Fall")),
                        DropdownMenuItem(value: 4, child: Text("Winter")),
                      ],
                      onChanged: (v) => setState(() => season = v!),
                    ),
                  ),
                ],
              ),
            ),

            // 🌦 WEATHER
            buildCard(
              child: Row(
                children: [
                  Icon(Icons.cloud, color: Colors.grey),
                  SizedBox(width: 20),
                  Expanded(
                    child: DropdownButton<int>(
                      value: weather,
                      isExpanded: true,
                      isDense: true,
                      underline: SizedBox(),
                      items: [
                        DropdownMenuItem(value: 1, child: Text("Clear ☀️")),
                        DropdownMenuItem(value: 2, child: Text("Cloudy 🌤")),
                        DropdownMenuItem(value: 3, child: Text("Rain 🌧")),
                        DropdownMenuItem(value: 4, child: Text("Storm 🌩")),
                      ],
                      onChanged: (v) => setState(() => weather = v!),
                    ),
                  ),
                ],
              ),
            ),

            // 🌡 INPUTS
            buildCard(
              child: Column(
                children: [
                  buildInput(
                    "Temperature",
                    Icons.thermostat,
                    tempController,
                    "°C",
                  ),
                  SizedBox(height: 10),
                  buildInput("Humidity", Icons.water_drop, humController, "%"),
                  SizedBox(height: 10),
                  buildInput("Wind Speed", Icons.air, windController, "km/h"),
                ],
              ),
            ),

            // 🎉 HOLIDAY
            buildCard(
              child: SwitchListTile(
                title: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.purple),
                    SizedBox(width: 10),
                    Text("Holiday"),
                  ],
                ),
                value: holiday,
                onChanged: (v) => setState(() => holiday = v),
              ),
            ),

            SizedBox(height: 20),

            // 🔄 BUTTON / LOADING
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: predict,
                      child: Text("Predict 🚴", style: TextStyle(fontSize: 18)),
                    ),
            ),

            // 📊 RESULT
            if (result.isNotEmpty)
              buildCard(
                child: Column(
                  children: [
                    Icon(Icons.directions_bike, size: 40, color: Colors.blue),
                    SizedBox(height: 10),
                    Text(
                      result,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
