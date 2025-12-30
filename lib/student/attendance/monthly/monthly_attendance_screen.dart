// monthly_attendance_screen.dart
import 'package:flutter/material.dart';

class MonthlyAttendanceView extends StatefulWidget {
  const MonthlyAttendanceView({super.key});

  @override
  State<MonthlyAttendanceView> createState() => _MonthlyAttendanceViewState();
}

class _MonthlyAttendanceViewState extends State<MonthlyAttendanceView> {
  DateTime _selectedMonth = DateTime.now();
  
  // Mock data - Replace with your actual data
  Map<int, AttendanceDay> _attendanceData = {};

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  void _loadMonthData() {
    // Mock attendance data
    _attendanceData = {
      1: AttendanceDay(attended: 5, total: 6),
      2: AttendanceDay(attended: 6, total: 6),
      3: AttendanceDay(attended: 4, total: 6),
      4: AttendanceDay(attended: 5, total: 6),
      5: AttendanceDay(attended: 6, total: 6),
      6: AttendanceDay(attended: 3, total: 5),
      7: AttendanceDay(attended: 0, total: 0), // Sunday - no classes
      8: AttendanceDay(attended: 5, total: 6),
      9: AttendanceDay(attended: 6, total: 6),
      10: AttendanceDay(attended: 4, total: 6),
      11: AttendanceDay(attended: 2, total: 5),
      12: AttendanceDay(attended: 3, total: 5),
      13: AttendanceDay(attended: 2, total: 5),
      14: AttendanceDay(attended: 0, total: 0), // Sunday
      15: AttendanceDay(attended: 5, total: 6),
      16: AttendanceDay(attended: 6, total: 6),
      17: AttendanceDay(attended: 4, total: 6),
      18: AttendanceDay(attended: 5, total: 6),
      19: AttendanceDay(attended: 6, total: 6),
      20: AttendanceDay(attended: 4, total: 6),
      21: AttendanceDay(attended: 0, total: 0), // Sunday
      22: AttendanceDay(attended: 5, total: 6),
      23: AttendanceDay(attended: 6, total: 6),
      24: AttendanceDay(attended: 4, total: 6),
      25: AttendanceDay(attended: 0, total: 0), // Holiday
      26: AttendanceDay(attended: 5, total: 6),
      27: AttendanceDay(attended: 3, total: 5),
      28: AttendanceDay(attended: 0, total: 0), // Sunday
      29: AttendanceDay(attended: 5, total: 6),
      30: AttendanceDay(attended: 6, total: 6),
      31: AttendanceDay(attended: 4, total: 6),
    };
    setState(() {});
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _loadMonthData();
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _loadMonthData();
    });
  }

  int _getTotalAttended() {
    return _attendanceData.values.fold(0, (sum, day) => sum + day.attended);
  }

  int _getTotalClasses() {
    return _attendanceData.values.fold(0, (sum, day) => sum + day.total);
  }

  double _getMonthlyPercentage() {
    final total = _getTotalClasses();
    if (total == 0) return 0;
    return _getTotalAttended() / total;
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Month Summary Card - Updated Design
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
                // ✅ Updated Circle Design - Same as Weekly
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          value: _getMonthlyPercentage(),
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2196F3),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "${(_getMonthlyPercentage() * 100).toInt()}%",
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
                        _getMonthName(_selectedMonth),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Total Classes Attended: ${_getTotalAttended()}/${_getTotalClasses()}",
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
                  onPressed: _previousMonth,
                  color: Colors.black87,
                ),
                Text(
                  _getMonthName(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 28),
                  onPressed: _nextMonth,
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
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
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
                final attendanceDay = _attendanceData[day];
                final isToday = day == DateTime.now().day &&
                    _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year;

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
          const _LegendItem(Colors.red, "Absent (<50%)"),
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

    if (attendanceDay != null && attendanceDay!.total > 0) {
      final percentage = attendanceDay!.attended / attendanceDay!.total;
      if (percentage >= 0.75) {
        indicatorColor = Colors.green;
      } else if (percentage >= 0.5) {
        indicatorColor = Colors.orange;
      } else {
        indicatorColor = Colors.red;
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
    final percentage = (data.attended / data.total * 100).toInt();
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

class AttendanceDay {
  final int attended;
  final int total;

  AttendanceDay({required this.attended, required this.total});
}