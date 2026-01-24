import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Weekly Schedule", 
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: c.loadTimetable,
          ),
        ],
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : c.errorMessage != null
              ? Center(child: Text(c.errorMessage!))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: c.orderedDays.length,
                  itemBuilder: (context, index) {
                    final day = c.orderedDays[index];
                    final periods = c.timetable[day] ?? [];
                    
                    if (periods.isEmpty) return const SizedBox.shrink();

                    return _DaySection(
                      day: day,
                      periods: periods,
                      isCurrentDay: DateFormat('EEEE').format(DateTime.now()) == day,
                    );
                  },
                ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final String day;
  final List<TimetablePeriod> periods;
  final bool isCurrentDay;

  const _DaySection({
    required this.day, 
    required this.periods, 
    required this.isCurrentDay
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
          child: Row(
            children: [
              Text(
                day.toUpperCase(),
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w900, 
                  color: isCurrentDay ? Colors.blueAccent : Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              if (isCurrentDay) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text("TODAY", 
                    style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ]
            ],
          ),
        ),
        ...periods.asMap().entries.map((entry) {
          return _TimelinePeriodTile(
            period: entry.value,
            isLast: entry.key == periods.length - 1,
            isCurrentDay: isCurrentDay,
          );
        }).toList(),
      ],
    );
  }
}

class _TimelinePeriodTile extends StatelessWidget {
  final TimetablePeriod period;
  final bool isLast;
  final bool isCurrentDay;

  const _TimelinePeriodTile({
    required this.period, 
    required this.isLast, 
    required this.isCurrentDay
  });

  bool get isOngoing {
    if (!isCurrentDay) return false;
    try {
      final now = DateTime.now();
      final format = DateFormat("hh:mm a");
      final start = format.parse(period.startTime);
      final end = format.parse(period.endTime);
      final current = format.parse(format.format(now));
      return current.isAfter(start) && current.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isOngoing ? Colors.blueAccent : Colors.grey[300]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOngoing ? Colors.blueAccent : Colors.white,
                  border: Border.all(color: accentColor, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey[200])),
            ],
          ),
          const SizedBox(width: 16),
          // Class Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isOngoing 
                    ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)) 
                    : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03), 
                      blurRadius: 10, 
                      offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Period ${period.periodNumber}",
                          style: TextStyle(
                            color: isOngoing ? Colors.blueAccent : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "${period.startTime} - ${period.endTime}",
                          style: TextStyle(
                            color: isOngoing ? Colors.blueAccent : Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      period.subjectName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Corrected academic icons and darker text for better visibility
                        _miniTag(Icons.business_center_outlined, "${period.branch}-${period.section}"),
                        const SizedBox(width: 12),
                        _miniTag(Icons.school_outlined, "Year ${period.year}"),
                        if (isOngoing) ...[
                          const Spacer(),
                          const Text("ONGOING", 
                            style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey[400]),
        const SizedBox(width: 6),
        Text(
          text, 
          style: TextStyle(
            color: Colors.blueGrey[800], // Darkened for faculty visibility
            fontSize: 12, 
            fontWeight: FontWeight.w500
          ),
        ),
      ],
    );
  }
}