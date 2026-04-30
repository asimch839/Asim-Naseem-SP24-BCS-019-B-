import 'package:flutter/material.dart';
import 'results_page.dart';
import 'settings_page.dart';
import '../calculator_brain.dart';

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  String selectedGender = 'Male';
  bool isCm = true;
  bool isKg = true;

  TextEditingController ageController = TextEditingController(text: '21');
  TextEditingController heightCmController = TextEditingController(text: '170');
  TextEditingController heightFtController = TextEditingController(text: '5');
  TextEditingController heightInController = TextEditingController(text: '7');
  TextEditingController weightController = TextEditingController(text: '70');

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color fieldColor = isDark ? const Color(0xFF1D1E33) : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('BMI Calculator',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildInputGroup('Age', ageController, textColor, fieldColor),
                    const SizedBox(height: 20),
                    _buildHeightInput(textColor, fieldColor),
                    const SizedBox(height: 20),
                    _buildGenderDropdown(textColor, fieldColor),
                    const SizedBox(height: 20),
                    _buildWeightInput(textColor, fieldColor),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  double h = 0;
                  if (isCm) {
                    h = double.tryParse(heightCmController.text) ?? 0;
                  } else {
                    double ft = double.tryParse(heightFtController.text) ?? 0;
                    double inc = double.tryParse(heightInController.text) ?? 0;
                    h = (ft * 30.48) + (inc * 2.54);
                  }

                  double w = double.tryParse(weightController.text) ?? 0;
                  if (!isKg) {
                    w = w / 2.20462; // Convert lb to kg
                  }

                  int? age = int.tryParse(ageController.text);

                  if (h > 0 && w > 0) {
                    CalculatorBrain calc = CalculatorBrain(height: h.toInt(), weight: w.toInt());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultsPage(
                          bmiResult: calc.calculateBMI(),
                          resultText: calc.getResult(),
                          interpretation: calc.getInterpretation(),
                          height: h,
                          weight: w,
                          age: age ?? 20,
                          gender: selectedGender,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D62ED),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('CALCULATE BMI',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightInput(Color textColor, Color fieldColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Height',
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text('ft', style: TextStyle(color: textColor.withOpacity(0.7))),
                Switch(
                  value: isCm,
                  onChanged: (v) => setState(() => isCm = v),
                  activeColor: const Color(0xFF2D62ED),
                ),
                Text('cm', style: TextStyle(color: textColor.withOpacity(0.7))),
              ],
            )
          ],
        ),
        const SizedBox(height: 8),
        if (isCm)
          _buildFieldRow(heightCmController, 'cm', textColor, fieldColor)
        else
          Row(
            children: [
              Expanded(child: _buildFieldRow(heightFtController, 'ft', textColor, fieldColor)),
              const SizedBox(width: 10),
              Expanded(child: _buildFieldRow(heightInController, 'in', textColor, fieldColor)),
            ],
          ),
      ],
    );
  }

  Widget _buildWeightInput(Color textColor, Color fieldColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Weight',
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text('lb', style: TextStyle(color: textColor.withOpacity(0.7))),
                Switch(
                  value: isKg,
                  onChanged: (v) => setState(() => isKg = v),
                  activeColor: const Color(0xFF2D62ED),
                ),
                const Text('kg', style: TextStyle(color: Colors.black54)),
              ],
            )
          ],
        ),
        const SizedBox(height: 8),
        _buildFieldRow(weightController, isKg ? 'kg' : 'lb', textColor, fieldColor),
      ],
    );
  }

  Widget _buildFieldRow(TextEditingController controller, String unit, Color textColor, Color fieldColor) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 55,
            decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textColor, fontSize: 18),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 15), border: InputBorder.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 55,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: fieldColor.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
            child: Text(unit, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildInputGroup(String label, TextEditingController controller, Color textColor, Color fieldColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 55,
          decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: textColor, fontSize: 18),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 15), border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown(Color textColor, Color fieldColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender',
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGender,
              isExpanded: true,
              dropdownColor: fieldColor,
              icon: Icon(Icons.keyboard_arrow_down, color: textColor.withOpacity(0.7)),
              items: ['Male', 'Female']
                  .map((String item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: TextStyle(color: textColor, fontSize: 18))))
                  .toList(),
              onChanged: (v) => setState(() {
                selectedGender = v!;
              }),
            ),
          ),
        ),
      ],
    );
  }
}
