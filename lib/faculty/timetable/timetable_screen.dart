import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timetable_controller.dart';

class TimetableScreen extends StatelessWidget {
  final String facultyId;
  const TimetableScreen({super.key, required this.facultyId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimetableController(facultyId: facultyId)..loadTimetable(),
      child: const _TimetableView(),
    );
  }
}

class _TimetableView extends StatelessWidget {
  const _TimetableView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TimetableController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Timetable"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: c.loadTimetable,
          ),
        ],
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : c.errorMessage != null
              ? Center(child: Text(c.errorMessage!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: c.orderedDays.map((day) {
                    final periods = c.timetable[day] ?? [];
                    if (periods.isEmpty) return const SizedBox.shrink();

                    return _DaySection(
                      day: day,
                      periods: periods,
                    );
                  }).toList(),
                ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final String day;
  final List<TimetablePeriod> periods;

  const _DaySection({required this.day, required this.periods});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ...periods.map((p) => _PeriodRow(period: p)),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final TimetablePeriod period;
  const _PeriodRow({required this.period});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text("P${period.periodNumber}"),
        title: Text(period.subjectName),
        subtitle: Text(
          "${period.subjectCode}\n${period.branch} • ${period.year} • ${period.section}",
        ),
        trailing: Text("${period.startTime} - ${period.endTime}"),
      ),
    );
  }
}
