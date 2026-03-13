import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/input_field.dart';
import '../models/cpa_model.dart';
import '../widgets/app_drawer.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _semesterNameController = TextEditingController();
  final _courseController = TextEditingController();
  final _creditsController = TextEditingController();

  final _theoryMidObt = TextEditingController();
  final _theoryMidTot = TextEditingController();
  final _theoryFinalObt = TextEditingController();
  final _theoryFinalTot = TextEditingController();

  final _numQuizzesController = TextEditingController();
  final _numAssignmentsController = TextEditingController();
  final _numLabAssignmentsController = TextEditingController();
  
  List<Map<String, TextEditingController>> _theoryQuizzes = [];
  List<Map<String, TextEditingController>> _theoryAssignments = [];

  final _labMidObt = TextEditingController();
  final _labMidTot = TextEditingController();
  final _labFinalObt = TextEditingController();
  final _labFinalTot = TextEditingController();
  List<Map<String, TextEditingController>> _labAssignments = [];

  final List<Semester> _semesters = [];
  Semester? _selectedSemester;
  double _overallCGPA = 0.0;
  bool _showResults = false;
  bool _isLabEnabled = false;

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addSemester() {
    if (_semesterNameController.text.isNotEmpty) {
      setState(() {
        final newSem = Semester(name: _semesterNameController.text, courses: []);
        _semesters.add(newSem);
        _selectedSemester = newSem;
        _semesterNameController.clear();
      });
      _showSnackBar('Semester Added Successfully', isError: false);
    } else {
      _showSnackBar('Please enter semester name');
    }
  }

  void _updateTheoryQuizzes(String value) {
    int count = int.tryParse(value) ?? 0;
    setState(() {
      _theoryQuizzes = List.generate(count, (index) => {
        'obt': TextEditingController(),
        'tot': TextEditingController(text: '10'),
      });
    });
  }

  void _updateTheoryAssignments(String value) {
    int count = int.tryParse(value) ?? 0;
    setState(() {
      _theoryAssignments = List.generate(count, (index) => {
        'obt': TextEditingController(),
        'tot': TextEditingController(text: '10'),
      });
    });
  }

  void _updateLabAssignments(String value) {
    int count = int.tryParse(value) ?? 0;
    setState(() {
      _labAssignments = List.generate(count, (index) => {
        'obt': TextEditingController(),
        'tot': TextEditingController(text: '10'),
      });
    });
  }

  bool _processAndAddCourse({bool silent = false}) {
    if (_selectedSemester == null) return false;
    if (_courseController.text.isEmpty) return false;

    final int? credits = int.tryParse(_creditsController.text);
    if (credits == null) return false;

    double totalObtained = 0;
    double totalMaxMarks = 0;

    void addMarks(TextEditingController obt, TextEditingController tot) {
      double o = double.tryParse(obt.text) ?? 0;
      double t = double.tryParse(tot.text) ?? 0;
      totalObtained += o;
      totalMaxMarks += t;
    }

    for (var q in _theoryQuizzes) addMarks(q['obt']!, q['tot']!);
    for (var a in _theoryAssignments) addMarks(a['obt']!, a['tot']!);
    addMarks(_theoryMidObt, _theoryMidTot);
    addMarks(_theoryFinalObt, _theoryFinalTot);

    if (_isLabEnabled) {
      for (var a in _labAssignments) addMarks(a['obt']!, a['tot']!);
      addMarks(_labMidObt, _labMidTot);
      addMarks(_labFinalObt, _labFinalTot);
    }

    if (totalMaxMarks <= 0) return false;

    setState(() {
      _selectedSemester!.courses.add(Course(
        name: _courseController.text,
        totalMarks: totalMaxMarks,
        obtainedMarks: totalObtained,
        credits: credits,
        isLab: _isLabEnabled,
      ));
      _clearCourseFields();
    });
    return true;
  }

  void _addCourse() {
    if (_processAndAddCourse()) {
      _showSnackBar('Subject Added Successfully', isError: false);
    } else {
      _showSnackBar('Please fill all details correctly');
    }
  }

  void _clearCourseFields() {
    _courseController.clear();
    _creditsController.clear();
    _theoryMidObt.clear(); _theoryMidTot.clear();
    _theoryFinalObt.clear(); _theoryFinalTot.clear();
    _labMidObt.clear(); _labMidTot.clear();
    _labFinalObt.clear(); _labFinalTot.clear();
    _numQuizzesController.clear();
    _numAssignmentsController.clear();
    _numLabAssignmentsController.clear();
    _theoryQuizzes.clear();
    _theoryAssignments.clear();
    _labAssignments.clear();
  }

  void _calculateAll() {
    if (_courseController.text.isNotEmpty) {
      _processAndAddCourse(silent: true);
    }

    if (_semesters.every((s) => s.courses.isEmpty)) {
      _showSnackBar('Add at least one subject first!');
      return;
    }

    setState(() {
      double totalSgpa = 0;
      for (var sem in _semesters) {
        sem.calculateSGPA();
        totalSgpa += sem.sgpa;
      }
      _overallCGPA = totalSgpa / _semesters.length;
      _showResults = true;
      
      // Save to History
      HistoryManager().addEntry(_overallCGPA, _semesters);
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_semesters.isEmpty) {
      return _buildInitialScreen();
    }
    return _buildDashboardScreen();
  }

  Widget _buildInitialScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA Tracker Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 24),
              const Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Add your first semester to get started', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              _buildCard(
                title: 'Create Semester',
                icon: Icons.add_circle_outline,
                child: Column(
                  children: [
                    InputField(label: 'Semester Name (e.g. 1st Semester)', controller: _semesterNameController),
                    const SizedBox(height: 16),
                    CustomButton(text: 'Get Started', onPressed: _addSemester),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            centerTitle: true,
            backgroundColor: theme.colorScheme.primary, 
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('GPA Tracker Pro', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60), 
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: CircularProgressIndicator(
                              value: _overallCGPA / 4.0,
                              strokeWidth: 10,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _overallCGPA.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '/ 4.00',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('OVERALL CGPA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCard(title: 'Add New Subject', icon: Icons.add_box_outlined, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    DropdownButtonFormField<Semester>(
                      value: _selectedSemester,
                      items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                      onChanged: (v) => setState(() => _selectedSemester = v),
                      decoration: const InputDecoration(labelText: 'Select Semester'),
                    ),
                    const SizedBox(height: 12),
                    InputField(label: 'Subject Name', controller: _courseController),
                    InputField(label: 'Credit Hours', controller: _creditsController, keyboardType: TextInputType.number),

                    SwitchListTile(
                      title: const Text('Includes Lab Components?', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: _isLabEnabled,
                      onChanged: (v) => setState(() => _isLabEnabled = v),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    const Text('No. Quizzes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    _buildCountInput('', _updateTheoryQuizzes, controller: _numQuizzesController),
                    ..._buildDynamicFields('Quiz', _theoryQuizzes),
                    
                    const SizedBox(height: 16),
                    const Text('No. Assignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    _buildCountInput('', _updateTheoryAssignments, controller: _numAssignmentsController),
                    ..._buildDynamicFields('Assignment', _theoryAssignments),
                    
                    const SizedBox(height: 16),
                    const Text('Theory Mid Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildObtTotRow('Mid Marks', _theoryMidObt, _theoryMidTot),
                    
                    const SizedBox(height: 16),
                    const Text('Theory Final Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildObtTotRow('Final Marks', _theoryFinalObt, _theoryFinalTot),

                    if (_isLabEnabled) ...[
                      const Divider(height: 40),
                      const SizedBox(height: 16),
                      const Text('No. Lab Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildCountInput('', _updateLabAssignments, controller: _numLabAssignmentsController),
                      ..._buildDynamicFields('Lab Assig', _labAssignments),
                      
                      const SizedBox(height: 16),
                      const Text('Lab Mid Marks', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildObtTotRow('Lab Mid', _labMidObt, _labMidTot),
                      
                      const SizedBox(height: 16),
                      const Text('Lab Final Marks', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildObtTotRow('Lab Final', _labFinalObt, _labFinalTot),
                    ],

                    const SizedBox(height: 24),
                    CustomButton(text: 'Save & Calculate', onPressed: _calculateAll),
                  ])),

                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'New Semester',
                    icon: Icons.add_circle_outline,
                    child: Row(
                      children: [
                        Expanded(child: InputField(label: 'Name', controller: _semesterNameController)),
                        const SizedBox(width: 8),
                        SizedBox(width: 100, child: CustomButton(text: 'Add', onPressed: _addSemester)),
                      ],
                    ),
                  ),

                  if (_showResults) ...[
                    const SizedBox(height: 24),
                    ..._semesters.map((sem) => _buildSemesterResult(sem)).toList(),
                    const SizedBox(height: 40),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountInput(String label, Function(String) onUpdate, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: label, 
        filled: true, 
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: onUpdate,
    );
  }

  List<Widget> _buildDynamicFields(String prefix, List<Map<String, TextEditingController>> controllers) {
    return controllers.asMap().entries.map((e) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('$prefix ${e.key + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        _buildObtTotRow('', e.value['obt']!, e.value['tot']!),
      ],
    )).toList();
  }

  Widget _buildObtTotRow(String label, TextEditingController obt, TextEditingController tot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        if (label.isNotEmpty) Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(child: TextField(
          controller: obt, 
          decoration: InputDecoration(
            hintText: 'Obtained', 
            filled: true, 
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ), 
          keyboardType: TextInputType.number,
        )),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: tot, 
          decoration: InputDecoration(
            hintText: 'Total', 
            filled: true, 
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ), 
          keyboardType: TextInputType.number,
        )),
      ]),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: Colors.blue), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
        const Divider(height: 20),
        child,
      ])),
    );
  }

  Widget _buildSemesterResult(Semester sem) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(sem.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Semester GPA: ${sem.sgpa.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        children: sem.courses.map((c) => ListTile(
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Normalized Marks: ${c.obtainedMarks.toStringAsFixed(1)}/100'),
              Text('Grade: ${c.grade}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('GP: ${c.gradePoint.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        )).toList(),
      ),
    );
  }
}
