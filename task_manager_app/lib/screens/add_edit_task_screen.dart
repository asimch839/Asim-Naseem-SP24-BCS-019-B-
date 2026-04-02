import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../providers/task_provider.dart'; // Now contains TaskController
import '../utils/helpers.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? editing;
  const AddEditTaskScreen({this.editing, Key? key}) : super(key: key);

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final TaskController controller = Get.find<TaskController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _title;
  late TextEditingController _desc;
  DateTime _due = DateTime.now();
  String _repeatType = 'none';
  List<int> _repeatDays = [];
  List<Subtask> _subtasks = [];
  bool _notify = true;

  double? _manualProgress;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.editing?.title ?? '');
    _desc = TextEditingController(text: widget.editing?.description ?? '');
    _selectedCategory = widget.editing?.category;
    if (widget.editing != null) {
      _due = widget.editing!.dueDate;
      _repeatType = widget.editing!.repeatType;
      _repeatDays = widget.editing!.repeatDays != null
          ? widget.editing!.repeatDays!.map((d) => _stringToWeekday(d)).toList()
          : [];
      _subtasks = widget.editing!.subtasks.map((s) => s.copy()).toList();
      _notify = widget.editing!.notificationId.isNotEmpty;
      _manualProgress = widget.editing!.progress * 100;
    }
  }

  int _stringToWeekday(String day) {
    switch (day) {
      case 'Mon': return 1;
      case 'Tue': return 2;
      case 'Wed': return 3;
      case 'Thu': return 4;
      case 'Fri': return 5;
      case 'Sat': return 6;
      case 'Sun': return 7;
      default: return 1;
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final safeInitial = _due.isBefore(now) ? now : _due;

    final date = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (time == null) return;

    setState(() => _due = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  double get _autoProgress {
    if (_subtasks.isEmpty) return 0;
    final done = _subtasks.where((s) => s.done).length;
    return (done / _subtasks.length) * 100;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    try {
      List<String> repeatDaysStr = _repeatDays
          .map((d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1])
          .toList();

      final task = TaskModel(
        id: widget.editing?.id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        dueDate: _due,
        isCompleted: widget.editing?.isCompleted ?? false,
        repeatType: _repeatType,
        repeatDays: repeatDaysStr,
        subtasks: _subtasks,
        progress: (_manualProgress ?? _autoProgress) / 100,
        notificationId: widget.editing?.notificationId ?? '',
        category: _selectedCategory,
      );

      if (widget.editing == null) {
        await controller.addTask(task, scheduleNotification: _notify);
      } else {
        await controller.updateTask(task, scheduleNotification: _notify);
      }

      Get.back();
      Get.snackbar('Success', widget.editing == null ? '✅ Task Saved!' : '✅ Task Updated!',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.7), colorText: Colors.white);

    } catch (e) {
      Get.snackbar('Error', '❌ $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFFF06292)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: isDark ? Colors.grey[900] : Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _title,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(labelText: 'Task Title', prefixIcon: Icon(Icons.title), border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _desc,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description), border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.label), border: OutlineInputBorder()),
              items: <String>['Work', 'Personal', 'Shopping', 'Others'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isDark ? Colors.purple[800] : const Color(0xFFE1BEE7)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('🗓️ ${formatDate(_due)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
                    const Icon(Icons.edit_calendar, color: Colors.purpleAccent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _repeatType,
              decoration: const InputDecoration(labelText: 'Repeat Type', border: OutlineInputBorder()),
              items: ['none', 'daily', 'weekly', 'custom'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _repeatType = v ?? 'none'),
            ),
            if (_repeatType == 'custom')
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final label = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];
                  final sel = _repeatDays.contains(i + 1);
                  return ChoiceChip(
                    label: Text(label),
                    selected: sel,
                    onSelected: (s) {
                      setState(() {
                        if (s) { _repeatDays.add(i + 1); } else { _repeatDays.remove(i + 1); }
                      });
                    },
                  );
                }),
              ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Enable Notification'),
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
              secondary: const Icon(Icons.notifications_active, color: Colors.purple),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Subtasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.purple, size: 30), onPressed: () => setState(() => _subtasks.add(Subtask(title: '', done: false)))),
              ],
            ),
            ..._subtasks.asMap().entries.map((e) {
              final idx = e.key;
              final s = e.value;
              return Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                child: ListTile(
                  leading: Checkbox(value: s.done, onChanged: (v) => setState(() => _subtasks[idx].done = v ?? false)),
                  title: TextFormField(
                    initialValue: s.title,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(hintText: 'Enter subtask name...', border: InputBorder.none),
                    onChanged: (val) => _subtasks[idx].title = val,
                  ),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => setState(() => _subtasks.removeAt(idx))),
                ),
              );
            }),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress: ${(_manualProgress ?? _autoProgress).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(value: _manualProgress ?? _autoProgress, min: 0, max: 100, divisions: 100, label: '${(_manualProgress ?? _autoProgress).toStringAsFixed(0)}%', onChanged: (val) => setState(() => _manualProgress = val)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _save,
              child: Text(isEditing ? 'Update Task' : 'Save Task', style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
