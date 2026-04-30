import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ResultsPage extends StatefulWidget {
  const ResultsPage({
    super.key,
    required this.interpretation,
    required this.bmiResult,
    required this.resultText,
    required this.height,
    required this.weight,
    required this.age,
    required this.gender,
  });

  final String bmiResult;
  final String resultText;
  final String interpretation;
  final double height;
  final double weight;
  final int age;
  final String gender;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  Future<void> _saveResult() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('bmi_history') ?? [];

      Map<String, dynamic> result = {
        'bmi': widget.bmiResult,
        'result': widget.resultText,
        'interpretation': widget.interpretation,
        'date': DateTime.now().toIso8601String(),
        'weight': widget.weight.toStringAsFixed(1),
        'height': widget.height.toStringAsFixed(1),
        'gender': widget.gender,
        'age': widget.age,
      };

      history.add(jsonEncode(result));
      await prefs.setStringList('bmi_history', history);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('BMI Result Saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save result.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Result?'),
        content: const Text('Are you sure you want to discard this calculation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to input page
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color surfaceColor = isDark ? const Color(0xFF1D1E33) : Colors.white;

    double targetBmi = double.tryParse(widget.bmiResult) ?? 0.0;

    // Weight conversions
    double weightKg = widget.weight;
    double weightLb = weightKg * 2.20462;

    // Height conversions
    double heightCm = widget.height;
    double totalInches = heightCm / 2.54;
    int feet = (totalInches / 12).floor();
    double inches = totalInches % 12;

    // Dynamic Ideal/Target Weight based on BMI
    double targetIdealBmi;
    String weightCardTitle;
    if (targetBmi < 18.5) {
      targetIdealBmi = 20.0; // Target for underweight
      weightCardTitle = 'Target Weight';
    } else if (targetBmi > 25.0) {
      targetIdealBmi = 23.0; // Target for overweight
      weightCardTitle = 'Target Weight';
    } else {
      targetIdealBmi = targetBmi; // Maintain if normal
      weightCardTitle = 'Ideal Weight';
    }

    double idealWeight = (targetIdealBmi * pow(widget.height / 100, 2)).toDouble();
    double minHealthyWeight = (18.5 * pow(widget.height / 100, 2)).toDouble();
    double maxHealthyWeight = (25.0 * pow(widget.height / 100, 2)).toDouble();

    double bmr = (10 * widget.weight) + (6.25 * widget.height) - (5 * widget.age);
    bmr = widget.gender == 'Male' ? bmr + 5 : bmr - 161;
    double tdee = bmr * 1.375;

    // BMI Based Calorie Goal
    String calorieGoalText;
    IconData calorieIcon;
    Color calorieColor;
    double targetCalories;

    if (targetBmi < 18.5) {
      calorieGoalText = 'Gain Weight';
      calorieIcon = Icons.trending_up;
      calorieColor = Colors.blue;
      targetCalories = tdee + 500;
    } else if (targetBmi >= 18.5 && targetBmi <= 25) {
      calorieGoalText = 'Maintain Weight';
      calorieIcon = Icons.horizontal_rule;
      calorieColor = Colors.green;
      targetCalories = tdee;
    } else {
      calorieGoalText = 'Lose Weight';
      calorieIcon = Icons.trending_down;
      calorieColor = Colors.orange;
      targetCalories = tdee - 500;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Target Result',
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _confirmDelete),
        ],
      ),
      body: Stack(
        children: [
          TweenAnimationBuilder<double>(
            key: UniqueKey(),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              double animatedBmi = targetBmi * value;

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10)
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _buildTopInfoItem(
                                  widget.gender == 'Male'
                                      ? Icons.person
                                      : Icons.person_3,
                                  widget.gender,
                                  Colors.blue,
                                  textColor),
                              _vDiv(),
                              _buildTopInfoItem(
                                  null,
                                  '${weightKg.toStringAsFixed(1)}kg / ${weightLb.toStringAsFixed(1)}lb',
                                  null,
                                  textColor),
                              _vDiv(),
                              _buildTopInfoItem(
                                  null,
                                  '${heightCm.toStringAsFixed(1)}cm / $feet\'${inches.toStringAsFixed(1)}"',
                                  null,
                                  textColor),
                              _vDiv(),
                              _buildTopInfoItem(null, 'Age: ${widget.age}', null, textColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            width: 300,
                            child: CustomPaint(
                                painter: ModernGaugePainter(bmi: animatedBmi, isDark: isDark)),
                          ),
                          Text('BMI',
                              style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500)),
                          Text(animatedBmi.toStringAsFixed(1),
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      child: Row(
                        children: [
                          _buildStatusTag(
                              '<16', 'Severe', const Color(0xFF1A237E), animatedBmi < 16, surfaceColor, isDark),
                          const SizedBox(width: 8),
                          _buildStatusTag('16-18.4', 'Under', const Color(0xFF42A5F5),
                              animatedBmi >= 16 && animatedBmi < 18.5, surfaceColor, isDark),
                          const SizedBox(width: 8),
                          _buildStatusTag('18.5-25', 'Normal', const Color(0xFF4CAF50),
                              animatedBmi >= 18.5 && animatedBmi <= 25, surfaceColor, isDark),
                          const SizedBox(width: 8),
                          _buildStatusTag('25-40', 'Over', const Color(0xFFFFA726),
                              animatedBmi > 25 && animatedBmi <= 40, surfaceColor, isDark),
                          const SizedBox(width: 8),
                          _buildStatusTag(
                              '>40', 'Obese', const Color(0xFFB71C1C), animatedBmi > 40, surfaceColor, isDark),
                        ],
                      ),
                    ),
                    _buildInsightCard(
                      icon: Icons.auto_graph,
                      title: 'BETTER THAN 49% USERS',
                      subtitle:
                          'Your BMI status is above average in your age group.',
                      isDark: isDark,
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text('WHO CLASSIFICATION',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                    ),
                    _buildClassificationTable(animatedBmi, surfaceColor, isDark),
                    _buildIdealWeightCard(
                        weightCardTitle, idealWeight * value, minHealthyWeight * value, maxHealthyWeight * value, surfaceColor, isDark),
                    _buildCalorieCard(
                      bmr * value,
                      tdee * value,
                      targetCalories * value,
                      calorieGoalText,
                      calorieIcon,
                      calorieColor,
                      surfaceColor,
                      isDark,
                    ),
                    _buildAdviceSection(
                        'Lifestyle Advice',
                        _getLifestyleAdvice(targetBmi),
                        Icons.check_circle_outline,
                        Colors.orangeAccent,
                        textColor),
                    _buildAdviceSection(
                        'Diet Advice',
                        _getDietAdvice(targetBmi),
                        Icons.restaurant,
                        Colors.green,
                        textColor),
                    _buildWaterTracker(targetBmi, isDark),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: surfaceColor.withOpacity(0.9),
              child: ElevatedButton(
                onPressed: _saveResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D62ED),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: const Text('SAVE RESULT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfoItem(IconData? icon, String text, Color? iconColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 20, color: iconColor ?? Colors.blue),
          if (icon != null) const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
        ],
      ),
    );
  }

  Widget _vDiv() =>
      Container(height: 20, width: 1.5, color: Colors.grey.withOpacity(0.2));

  Widget _buildStatusTag(
      String range, String label, Color color, bool selected, Color surfaceColor, bool isDark) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color : surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? color : Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(range,
              style: TextStyle(
                  color: selected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required bool isDark}) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1E33) : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: Colors.blue.withOpacity(0.1)) : null),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.white,
              child: Icon(icon, color: Colors.blueAccent)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFF2D62ED),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationTable(double bmi, Color surfaceColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Column(
        children: [
          _classRow('Severe Thinness', '< 16.0', const Color(0xFF1A237E), bmi < 16.0, isDark),
          _classRow('Moderate Thinness', '16.0 - 16.9', const Color(0xFF3949AB),
              bmi >= 16.0 && bmi <= 16.9, isDark),
          _classRow('Mild Thinness', '17.0 - 18.4', const Color(0xFF42A5F5),
              bmi >= 17.0 && bmi <= 18.4, isDark),
          _classRow('Normal', '18.5 - 24.9', const Color(0xFF4CAF50),
              bmi >= 18.5 && bmi <= 24.9, isDark),
          _classRow('Overweight', '25.0 - 29.9', const Color(0xFFFFA726),
              bmi >= 25.0 && bmi <= 29.9, isDark),
          _classRow('Obese Class I', '30.0 - 34.9', const Color(0xFFFB8C00),
              bmi >= 30.0 && bmi <= 34.9, isDark),
          _classRow('Obese Class II', '35.0 - 39.9', const Color(0xFFF4511E),
              bmi >= 35.0 && bmi <= 39.9, isDark),
          _classRow('Obese Class III', '>= 40.0', const Color(0xFFB71C1C),
              bmi >= 40.0, isDark),
        ],
      ),
    );
  }

  Widget _classRow(String label, String range, Color color, bool active, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: active ? (isDark ? const Color(0xFF0A0E21) : Colors.white) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: active ? const Color(0xFFFFD700) : Colors.transparent,
            width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black)),
          const Spacer(),
          Text(range,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildIdealWeightCard(String title, double ideal, double min, double max, Color surfaceColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: isDark 
                ? [surfaceColor, const Color(0xFF0A0E21)]
                : [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome, color: Colors.orange.shade300, size: 20),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black))
          ]),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${ideal.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                      color: Color(0xFF2D62ED),
                      fontSize: 40,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Healthy Range',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)} kg',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCalorieCard(double bmr, double tdee, double target, String goal, IconData icon, Color color, Color surfaceColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1E33) : const Color(0xFFF3E5F5).withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.purple.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bolt, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            Text('Daily Calorie Budget',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black))
          ]),
          const SizedBox(height: 15),
          _calRow('BMR', '${bmr.toInt()} kcal', isDark),
          _calRow('TDEE (Moderate Activity)', '${tdee.toInt()} kcal', isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Text('$goal: ${target.toInt()} kcal',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold))
            ]),
          )
        ],
      ),
    );
  }

  Widget _calRow(String label, String val, bool isDark) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(val,
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black))
          ]));

  Widget _buildAdviceSection(
      String title, List<String> advice, IconData icon, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 4, height: 20, color: color),
            const SizedBox(width: 10),
            Text(title,
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor))
          ]),
          const SizedBox(height: 15),
          ...advice.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item,
                            style: TextStyle(
                                color: textColor.withOpacity(0.7), fontSize: 14))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<String> _getLifestyleAdvice(double bmi) {
    if (bmi < 17) {
      return [
        'Engage in strength training to build muscle mass safely.',
        'Prioritize 8-9 hours of sleep for cellular repair.',
        'Reduce high-intensity cardio to prevent weight loss.',
        'Consult a doctor to rule out nutritional deficiencies.'
      ];
    } else if (bmi < 18.5) {
      return [
        'Incorporate resistance exercises (push-ups, squats).',
        'Maintain a consistent sleep schedule (7-8 hours).',
        'Stay active but avoid over-training.',
        'Monitor your energy levels during physical activity.'
      ];
    } else if (bmi <= 25) {
      return [
        'Aim for 150 minutes of moderate activity per week.',
        'Take the stairs instead of the elevator whenever possible.',
        'Practice mindfulness or meditation for stress management.',
        'Get at least 7-8 hours of quality sleep nightly.'
      ];
    } else if (bmi <= 30) {
      return [
        'Aim for 10,000 steps daily to boost calorie burn.',
        'Combine cardio (walking, swimming) with light weights.',
        'Stand more throughout the day (use a standing desk).',
        'Avoid late-night screen time to improve sleep quality.'
      ];
    } else {
      return [
        'Start with low-impact exercises like walking or water aerobics.',
        'Focus on consistency: even 15-20 mins daily helps.',
        'Ensure proper rest; weight loss happens during recovery.',
        'Consult a professional for a personalized fitness plan.'
      ];
    }
  }

  List<String> _getDietAdvice(double bmi) {
    if (bmi < 17) {
      return [
        'Eat calorie-dense whole foods (nuts, seeds, nut butters).',
        'Have 5-6 small meals throughout the day.',
        'Include full-fat dairy, avocados, and healthy oils.',
        'Drink high-protein shakes between your main meals.'
      ];
    } else if (bmi < 18.5) {
      return [
        'Focus on lean proteins like chicken, fish, or beans.',
        'Add healthy fats to every meal (olive oil, almonds).',
        'Don\'t skip meals, especially breakfast.',
        'Snack on dried fruits or Greek yogurt.'
      ];
    } else if (bmi <= 25) {
      return [
        'Eat a colorful variety of fruits and vegetables.',
        'Choose whole grains (brown rice, oats) over refined ones.',
        'Drink 2-3 liters of water daily to stay hydrated.',
        'Keep portion sizes moderate and avoid processed sugar.'
      ];
    } else if (bmi <= 30) {
      return [
        'Reduce portion sizes by using smaller plates.',
        'Limit liquid calories like sodas, juices, and alcohol.',
        'Fill half your plate with non-starchy vegetables.',
        'Eat slowly to give your brain time to register fullness.'
      ];
    } else {
      return [
        'Prioritize a high-protein, high-fiber diet for satiety.',
        'Strictly limit ultra-processed and sugary foods.',
        'Try Intermittent Fasting (e.g., 16:8 window) if suitable.',
        'Keep a food journal to identify hidden calorie sources.'
      ];
    }
  }

  Widget _buildWaterTracker(double bmi, bool isDark) {
    List<String> waterAdvice = _getWaterAdvice(bmi);
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D47A1).withOpacity(0.2) : const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.water_drop, color: Colors.blue, size: 20),
            const SizedBox(width: 10),
            Text('Water Tracker',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1)))
          ]),
          const SizedBox(height: 15),
          ...waterAdvice.map((item) => _waterItem(item, isDark)),
        ],
      ),
    );
  }

  List<String> _getWaterAdvice(double bmi) {
    if (bmi < 18.5) {
      return [
        'Drink water between meals rather than during them.',
        'Stay hydrated for optimal metabolism and absorption.',
        'Daily goal: 2000-2500ml',
      ];
    } else if (bmi <= 25) {
      return [
        'Drink a glass of water right after waking up.',
        '500ml water 30 mins before meals for digestion.',
        'Daily goal: 2500-3000ml',
      ];
    } else {
      return [
        'Drink 500ml water before every meal to curb appetite.',
        'Replace all sugary drinks with plain water.',
        'Daily goal: 3000-3500ml (more if active)',
      ];
    }
  }

  Widget _waterItem(String text, bool isDark) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        const Icon(Icons.check_circle, color: Colors.blue, size: 16),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: isDark ? Colors.blue.shade200 : const Color(0xFF1565C0), fontSize: 14)))
      ]));
}

class ModernGaugePainter extends CustomPainter {
  final double bmi;
  final bool isDark;
  ModernGaugePainter({required this.bmi, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final List<Map<String, dynamic>> segments = [
      {'start': pi, 'sweep': pi * 0.15, 'color': const Color(0xFF1A237E)},
      {'start': pi * 1.15, 'sweep': pi * 0.1, 'color': const Color(0xFF42A5F5)},
      {'start': pi * 1.25, 'sweep': pi * 0.25, 'color': const Color(0xFF4CAF50)},
      {'start': pi * 1.5, 'sweep': pi * 0.3, 'color': const Color(0xFFFFA726)},
      {'start': pi * 1.8, 'sweep': pi * 0.2, 'color': const Color(0xFFB71C1C)},
    ];

    final paint = Paint()
      ..strokeWidth = 35
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    for (var segment in segments) {
      paint.color = segment['color'];
      canvas.drawArc(rect, segment['start'], segment['sweep'], false, paint);
    }

    // Needle
    final needlePaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF2C3E50)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Normalize BMI for gauge (from 10 to 50)
    double normalizedBmi = (bmi - 10) / 40;
    normalizedBmi = normalizedBmi.clamp(0.0, 1.0);
    double angle = pi + (normalizedBmi * pi);

    final needleEnd = Offset(center.dx + radius * 0.85 * cos(angle),
        center.dy + radius * 0.85 * sin(angle));
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 10, Paint()..color = isDark ? Colors.white : const Color(0xFF2C3E50));
    canvas.drawCircle(center, 4, Paint()..color = isDark ? const Color(0xFF0A0E21) : Colors.white);

    // Static markers
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    void drawText(String text, double angle) {
      textPainter.text = TextSpan(
          text: text,
          style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold));
      textPainter.layout();
      double x = center.dx + (radius + 20) * cos(angle) - (textPainter.width / 2);
      double y = center.dy + (radius + 20) * sin(angle) - (textPainter.height / 2);
      textPainter.paint(canvas, Offset(x, y));
    }

    drawText('16', pi * 1.15);
    drawText('18.5', pi * 1.25);
    drawText('25', pi * 1.5);
    drawText('30', pi * 1.8);
    drawText('40', pi * 2.0);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
