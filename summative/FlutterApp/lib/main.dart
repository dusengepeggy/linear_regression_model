import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBaseUrl = "https://linear-regression-model-kkrq.onrender.com";


const Color kBackground = Color(0xFF0B0B0F);
const Color kCard = Color(0xFF17171C);
const Color kCardAlt = Color(0xFF1F1F26);
const Color kAccent = Color(0xFFE63950);
const Color kTextMuted = Color(0xFF9A9AA5);

void main() {
  runApp(const YouthIncomeApp());
}

class YouthIncomeApp extends StatelessWidget {
  const YouthIncomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Youth Income Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackground,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _ageController = TextEditingController();
  final _hoursController = TextEditingController();

  static const educationOptions = [
    "Primary",
    "Lower_secondary",
    "Upper_secondary",
    "University",
  ];
  static const sexOptions = ["Male", "Female"];
  static const urbanRuralOptions = ["Urban", "Rural"];
  static const provinceOptions = [
    "Kigali city",
    "Northern Province",
    "Southern Province",
    "Eastern Province",
    "Western Province",
  ];
  static const sectorOptions = ["Agriculture", "Industry", "Services"];

  String? _education;
  String? _sex;
  String? _urbanRural;
  String? _province;
  String? _sector;

  bool _isLoading = false;
  String? _errorMessage;
  double? _predictedHourly;
  double? _predictedMonthly;

  @override
  void dispose() {
    _ageController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    setState(() {
      _errorMessage = null;
      _predictedHourly = null;
      _predictedMonthly = null;
    });

    // ---- Client-side validation (mirrors the API's Pydantic constraints) ----
    final age = int.tryParse(_ageController.text.trim());
    final hours = double.tryParse(_hoursController.text.trim());

    if (age == null || age < 16 || age > 30) {
      setState(() => _errorMessage = "Age must be a number between 16 and 30.");
      return;
    }
    if (hours == null || hours <= 0 || hours > 112) {
      setState(() => _errorMessage = "Hours worked must be between 1 and 112.");
      return;
    }
    if (_education == null ||
        _sex == null ||
        _urbanRural == null ||
        _province == null ||
        _sector == null) {
      setState(() => _errorMessage = "Please fill in every field before predicting.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/predict"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "age": age,
          "hours_worked": hours,
          "education": _education,
          "sex": _sex,
          "urban_rural": _urbanRural,
          "province": _province,
          "sector": _sector,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _predictedHourly = (data["predicted_hourly_income_rwf"] as num).toDouble();
          _predictedMonthly = (data["predicted_monthly_income_rwf"] as num).toDouble();
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data["detail"]?.toString() ??
              "Something went wrong (status ${response.statusCode}). Please check your inputs.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Could not reach the prediction service. Check your connection and try again.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildResultCard(),
              const SizedBox(height: 28),
              const Text(
                "Your Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _ageController,
                label: "Age (16–30)",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _hoursController,
                label: "Hours worked per week",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: "Education level",
                value: _education,
                items: educationOptions,
                onChanged: (v) => setState(() => _education = v),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: "Sex",
                value: _sex,
                items: sexOptions,
                onChanged: (v) => setState(() => _sex = v),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: "Urban or rural",
                value: _urbanRural,
                items: urbanRuralOptions,
                onChanged: (v) => setState(() => _urbanRural = v),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: "Province",
                value: _province,
                items: provinceOptions,
                onChanged: (v) => setState(() => _province = v),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: "Sector",
                value: _sector,
                items: sectorOptions,
                onChanged: (v) => setState(() => _sector = v),
              ),
              const SizedBox(height: 24),
              _buildPredictButton(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorBanner(_errorMessage!),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.insights_rounded, color: kAccent),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            "Youth Income Predictor",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final hasResult = _predictedHourly != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Estimated Earning Potential",
                style: TextStyle(color: kTextMuted, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "RWF",
                  style: TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 3, color: kAccent),
              ),
            )
          else if (hasResult) ...[
            Text(
              "${_predictedHourly!.toStringAsFixed(0)} RWF / hour",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "≈ ${_predictedMonthly!.toStringAsFixed(0)} RWF / month",
              style: const TextStyle(color: kTextMuted, fontSize: 14),
            ),
          ] else
            const Text(
              "Fill in the details below and tap Predict",
              style: TextStyle(color: kTextMuted, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextMuted),
        filled: true,
        fillColor: kCardAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: kCardAlt,
      style: const TextStyle(color: Colors.white),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kTextMuted),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextMuted),
        filled: true,
        fillColor: kCardAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item.replaceAll("_", " ")),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _predict,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Text(
                "Predict",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
