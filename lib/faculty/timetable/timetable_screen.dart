import 'package:flutter/material.dart';
import 'timetable_controller.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TimetableController();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("My Timetable"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: controller.timetable.entries.map((entry) {
          return _DaySection(
            day: entry.key,
            periods: entry.value,
          );
        }).toList(),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final String day;
  final List<TimetablePeriod> periods;

  const _DaySection({
    required this.day,
    required this.periods,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Divider(thickness: 1),
              ),
            ],
          ),
        ),

        if (periods.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "No classes",
              style: TextStyle(color: Colors.grey),
            ),
          ),

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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "P${period.periodNumber}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${period.startTime}\n${period.endTime}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Divider
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade300,
          ),

          const SizedBox(width: 14),

          // Subject details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.subjectName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  period.subjectCode,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${period.branch} • ${period.year} • ${period.section}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
