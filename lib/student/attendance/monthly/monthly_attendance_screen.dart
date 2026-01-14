import 'package:flutter/material.dart';
import 'monthly_attendance_controller.dart';

class MonthlyAttendanceView extends StatefulWidget {
  const MonthlyAttendanceView({super.key});

  @override
  State<MonthlyAttendanceView> createState() => _MonthlyAttendanceViewState();
}

class _MonthlyAttendanceViewState extends State<MonthlyAttendanceView> {
  final MonthlyAttendanceController _controller = MonthlyAttendanceController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.loadMonthlyAttendance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Month Summary Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: _controller.getMonthlyPercentage(),
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            "${(_controller.getMonthlyPercentage() * 100).toInt()}%",
                            style: const TextStyle(
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _controller.getMonthName(_controller.selectedMonth),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Total Classes Attended: ${_controller.getTotalAttended()}/${_controller.getTotalClasses()}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Month Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: _controller.previousMonth,
                    color: Colors.black87,
                  ),
                  Text(
                    _controller.getMonthName(_controller.selectedMonth),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: _controller.nextMonth,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Weekday Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Calendar Grid
            _buildCalendarGrid(),

            const SizedBox(height: 16),

            // Legend
            _buildLegend(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_controller.selectedMonth.year, _controller.selectedMonth.month, 1);
    final lastDay = DateTime(_controller.selectedMonth.year, _controller.selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7; // 0 = Sunday

    // Calculate number of rows needed
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(rows, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: List.generate(7, (colIndex) {
                final cellIndex = rowIndex * 7 + colIndex;

                if (cellIndex < firstWeekday || cellIndex >= firstWeekday + daysInMonth) {
                  return const Expanded(child: SizedBox(height: 60));
                }

                final day = cellIndex - firstWeekday + 1;
                final attendanceDay = _controller.attendanceData[day];
                final isToday = day == DateTime.now().day &&
                    _controller.selectedMonth.month == DateTime.now().month &&
                    _controller.selectedMonth.year == DateTime.now().year;

                return Expanded(
                  child: _DayCell(
                    day: day,
                    attendanceDay: attendanceDay,
                    isToday: isToday,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _LegendItem(Colors.green, "Present (>75%)"),
              _LegendItem(Colors.orange, "Partial (50-75%)"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _LegendItem(Colors.red, "Absent (<50%)"),
              _LegendItem(Colors.grey, "No Classes"),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final AttendanceDay? attendanceDay;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.attendanceDay,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorColor = Colors.grey.shade300;
    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black87;

    if (attendanceDay != null) {
      if (attendanceDay!.total > 0) {
        final percentage = attendanceDay!.percentage;
        if (percentage >= 0.75) {
          indicatorColor = Colors.green;
        } else if (percentage >= 0.5) {
          indicatorColor = Colors.orange;
        } else {
          indicatorColor = Colors.red;
        }
      } else {
        // No classes (weekend/holiday)
        indicatorColor = Colors.grey.shade400;
      }
    }

    if (isToday) {
      backgroundColor = const Color(0xFF2196F3).withValues(alpha: 0.1);
      textColor = const Color(0xFF2196F3);
    }

    return GestureDetector(
      onTap: () {
        if (attendanceDay != null && attendanceDay!.total > 0) {
          _showDayDetails(context, day, attendanceDay!);
        }
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: const Color(0xFF2196F3), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$day",
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            if (attendanceDay != null && attendanceDay!.total > 0)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              )
            else if (attendanceDay != null && attendanceDay!.total == 0)
              Icon(
                Icons.remove_circle_outline,
                size: 10,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(BuildContext context, int day, AttendanceDay data) {
    final percentage = (data.percentage * 100).toInt();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Day $day Attendance"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow("Classes Attended", "${data.attended}"),
            _DetailRow("Total Classes", "${data.total}"),
            _DetailRow("Percentage", "$percentage%"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}