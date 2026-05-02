import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/helpers/date_helper.dart';
import '../../core/routes/app_routes.dart';
import '../../models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/cards/priority_badge.dart';
import '../../widgets/common/empty_state_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<NoteModel> _dayNotes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadNotes(_selectedDay);
  }

  Future<void> _loadNotes(DateTime day) async {
    setState(() => _loading = true);
    _dayNotes = await context.read<NotesProvider>().getNotesByDate(day);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar 📅'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              leftChevronIcon: Icon(Icons.chevron_left_rounded,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
              rightChevronIcon: Icon(Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(fontWeight: FontWeight.w700),
              selectedTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
              defaultTextStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              weekendTextStyle: const TextStyle(color: AppColors.secondary),
              outsideTextStyle: TextStyle(
                color:
                    isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
              ),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _loadNotes(selected);
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                const Icon(Icons.event_note_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  DateHelper.formatDate(_selectedDay),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${_dayNotes.length} note${_dayNotes.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _dayNotes.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.event_busy_rounded,
                        title: 'No Notes',
                        subtitle: 'No notes created on this day',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: _dayNotes.length,
                        itemBuilder: (_, i) => _CalendarNoteRow(
                            note: _dayNotes[i], isDark: isDark),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CalendarNoteRow extends StatelessWidget {
  final NoteModel note;
  final bool isDark;

  const _CalendarNoteRow({required this.note, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.noteEditor, arguments: note),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                    color: Color(note.colorValue == 0xFFFFFFFF
                        ? 0xFF6C63FF
                        : note.colorValue),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(DateHelper.formatTime(note.createdAt),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            PriorityBadge(priority: note.priority, compact: true),
          ],
        ),
      ),
    );
  }
}
