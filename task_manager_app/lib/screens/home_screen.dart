import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/task_provider.dart';
import '../screens/add_edit_task_screen.dart';
import '../models/task_model.dart';
import 'settings_screen.dart';
import 'view_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskController controller = Get.find<TaskController>();
  int _index = 1; 
  String _searchQuery = '';
  String _sortOption = 'Date';
  String _filterCategory = 'All';
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profileImagePath');
    if (!mounted) return;
    setState(() {
      _profileImagePath = savedPath != null && File(savedPath).existsSync() ? savedPath : null;
    });
  }

  Future<void> _resetProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileImagePath');
    if (!mounted) return;
    setState(() => _profileImagePath = null);
    Get.snackbar('Profile', 'Profile reset to default', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _changeProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result == null || result.files.single.path == null) return;
    final sourcePath = result.files.single.path!;
    final appDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(sourcePath).toLowerCase();
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final targetPath = p.join(appDir.path, 'profile_photo$safeExt');
    final copiedFile = await File(sourcePath).copy(targetPath);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', copiedFile.path);
    if (!mounted) return;
    setState(() => _profileImagePath = copiedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.22),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFFF06292)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
              child: Obx(() {
                final totalTasks = controller.tasks.length;
                final completedCount = controller.tasks.where((t) => t.isCompleted).length;
                final progress = totalTasks == 0 ? 0.0 : completedCount / totalTasks;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            Get.defaultDialog(
                              title: "Profile Photo",
                              middleText: "Do you want to reset to default photo?",
                              textCancel: "Cancel",
                              textConfirm: "Reset",
                              confirmTextColor: Colors.white,
                              onConfirm: () {
                                _resetProfileImage();
                                Get.back();
                              },
                            );
                          },
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: screenWidth * 0.07,
                                backgroundImage: _profileImagePath != null
                                    ? FileImage(File(_profileImagePath!))
                                    : const AssetImage('assets/images/profile.jpeg') as ImageProvider,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _changeProfileImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Icon(Icons.camera_alt, size: screenWidth * 0.04, color: Colors.purple),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "✨ Task Manager",
                                style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                DateFormat('EEEE, MMM d, yyyy').format(now),
                                style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.035),
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () => Get.to(() => const SettingsScreen())),
                        IconButton(
                          icon: Icon(controller.isDark.value ? Icons.wb_sunny_outlined : Icons.nightlight_round, color: Colors.white),
                          onPressed: () => controller.toggleTheme(),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (totalTasks > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: progress, backgroundColor: Colors.white24, color: Colors.white, minHeight: 6, borderRadius: BorderRadius.circular(10)),
                          const SizedBox(height: 6),
                          Text(
                            "Completed: $completedCount / $totalTasks  (${(progress * 100).toStringAsFixed(0)}%)",
                            style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.032),
                          ),
                        ],
                      )
                    else
                      Text("No tasks yet. Add your first one!", style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.035)),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.015, screenWidth * 0.04, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: "Search tasks...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: controller.isDark.value ? Colors.grey[850] : Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Colors.purple),
                  onSelected: (value) => setState(() => _sortOption = value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Date', child: Text('Sort by Date')),
                    PopupMenuItem(value: 'Progress', child: Text('Sort by Progress')),
                    PopupMenuItem(value: 'Status', child: Text('Sort by Status')),
                  ],
                ),
              ],
            ),
          ),
          Obx(() => SizedBox(
            height: screenHeight * 0.06,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.005),
              children: [
                _buildCategoryChip('All'),
                ...controller.tasks.map((t) => t.category ?? 'Others').toSet().map((c) => _buildCategoryChip(c)).toList()
              ],
            ),
          )),
          Expanded(
            child: Obx(() {
              final tasks = _getFilteredTasks();
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildList(tasks),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFAB47BC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Get.to(() => const AddEditTaskScreen()),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8E24AA),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'All'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Completed'),
          BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Repeated'),
        ],
      ),
    );
  }

  List<TaskModel> _getFilteredTasks() {
    List<TaskModel> list = [];
    final now = DateTime.now();

    if (_index == 0) {
      list = controller.tasks.where((t) => t.dueDate.year == now.year && t.dueDate.month == now.month && t.dueDate.day == now.day && !t.isCompleted).toList();
    } else if (_index == 1) {
      list = controller.tasks;
    } else if (_index == 2) {
      list = controller.tasks.where((t) => t.isCompleted).toList();
    } else {
      list = controller.tasks.where((t) => t.repeatType != 'none').toList();
    }

    var filteredList = list.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _filterCategory == 'All' || (t.category ?? 'Others') == _filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    if (_sortOption == 'Date') {
      filteredList.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (_sortOption == 'Progress') {
      filteredList.sort((a, b) => b.progress.compareTo(a.progress));
    }

    return filteredList;
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _filterCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterCategory = category),
        selectedColor: Colors.purple,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildList(List<TaskModel> filteredList) {
    if (filteredList.isEmpty) return const Center(child: Text('No tasks found.', style: TextStyle(fontSize: 18, color: Colors.black54)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      itemBuilder: (context, i) => _buildTaskCard(filteredList[i]),
    );
  }

  Widget _buildTaskCard(TaskModel t) {
    double screenWidth = MediaQuery.of(context).size.width;
    final taskProgress = t.isCompleted ? 1.0 : t.progress;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (t.category != null)
                        Text(t.category!, style: const TextStyle(fontSize: 12, color: Colors.purple)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.visibility, color: Colors.blue), onPressed: () => Get.to(() => ViewTaskScreen(task: t))),
                if (!t.isCompleted)
                  IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => Get.to(() => AddEditTaskScreen(editing: t))),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.deleteTask(t)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: taskProgress, backgroundColor: Colors.grey[200], color: Colors.purple, minHeight: 6, borderRadius: BorderRadius.circular(10)),
            
            if (t.subtasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Subtasks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ...t.subtasks.asMap().entries.map((entry) {
                var sub = entry.value;
                return InkWell(
                  onTap: () {
                    // Prevent modifying subtasks if task is already completed
                    if (t.isCompleted) return;

                    sub.done = !sub.done;
                    final doneCount = t.subtasks.where((s) => s.done).length;
                    t.progress = doneCount / t.subtasks.length;
                    controller.updateTask(t);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(sub.done ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: sub.done ? Colors.green : Colors.grey),
                        const SizedBox(width: 8),
                        Text(sub.title, style: TextStyle(fontSize: 14, decoration: sub.done ? TextDecoration.lineThrough : null, color: sub.done ? Colors.grey : (controller.isDark.value ? Colors.white70 : Colors.black87))),
                      ],
                    ),
                  ),
                );
              }),
            ],

            if (!t.isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: t.isCompleted,
                    activeColor: Colors.purple,
                    onChanged: (val) {
                      if (t.subtasks.any((s) => !s.done)) {
                        Get.snackbar('Alert', '⚠️ Complete all subtasks first!', snackPosition: SnackPosition.BOTTOM);
                      } else {
                        controller.toggleTaskCompletion(t);
                      }
                    },
                  ),
                  const Text("Mark Task as Done"),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
