import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'long_reports_controller.dart';

class LongReportsScreen extends StatelessWidget {
  final String facultyId;
  const LongReportsScreen({super.key, required this.facultyId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LongReportsController(facultyId: facultyId),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  /// yyyy-MM → Feb 2026
  String _prettyMonth(String ym) {
    final parts = ym.split('-');
    if (parts.length != 2) return ym;

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${names[month - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LongReportsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Monthly Attendance',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _selectors(c),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.table_chart),
              label: const Text(
                'View Attendance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: c.loading
                  ? null
                  : () async {
                      final ok = await c.loadReport();
                      if (!context.mounted) return;

                      if (ok) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => _Grid(c)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No data found')),
                        );
                      }
                    },
            ),
          ),
        ),
      ),
    );
  }

  /// ===============================================================
  /// BEAUTIFUL DROPDOWNS
  /// ===============================================================
  Widget _selectors(LongReportsController c) {
    Widget drop(
      String label,
      String? value,
      List<String> items,
      void Function(String?) onChanged, {
      bool loading = false,
      IconData? icon,
      String Function(String)? display,
    }) {
      return DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        menuMaxHeight: 300,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    display != null ? display(e) : e,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: items.isEmpty ? null : onChanged,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Class Details'),
        _card(
          child: Column(
            children: [
              drop(
                'Year',
                c.year,
                ['1', '2', '3', '4'],
                (v) {
                  c.year = v;
                  c.subject = null;
                  c.fetchSubjects();
                },
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 14),
              drop(
                'Branch',
                c.branch,
                ['AIML', 'AIDS'],
                (v) {
                  c.branch = v;
                  c.subject = null;
                  c.fetchSubjects();
                },
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 14),
              drop(
                'Section',
                c.section,
                ['A', 'B'],
                (v) {
                  c.section = v;
                  c.subject = null;
                  c.fetchSubjects();
                },
                icon: Icons.group_outlined,
              ),
              const SizedBox(height: 14),
              drop(
                'Subject',
                c.subject,
                c.availableSubjects,
                (v) => c.subject = v,
                loading: c.loadingSubjects,
                icon: Icons.menu_book_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Report Options'),
        _card(
          child: Column(
            children: [
              drop(
                'Month',
                c.month,
                c.availableMonths,
                (v) => c.month = v,
                loading: c.loadingMonths,
                icon: Icons.calendar_month_outlined,
                display: _prettyMonth,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ReportRange>(
                initialValue: c.range,
                menuMaxHeight: 300,
                decoration: InputDecoration(
                  labelText: 'Report Duration',
                  prefixIcon: const Icon(Icons.timelapse_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 8,
                items: const [
                  DropdownMenuItem(
                    value: ReportRange.fullMonth,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Full Month'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: ReportRange.firstHalf,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Days 1 – 15'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: ReportRange.secondHalf,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Days 16 – End'),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) c.range = v;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// ===============================================================
/// ====================== GRID SCREEN =============================
/// ===============================================================

class _Grid extends StatefulWidget {
  final LongReportsController c;
  const _Grid(this.c);

  @override
  State<_Grid> createState() => _GridState();
}

/// 🔥 Faster scroll physics (safe & smooth)
class FastScrollPhysics extends ClampingScrollPhysics {
  const FastScrollPhysics({super.parent});

  @override
  FastScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset * 1.6;
  }
}

class _GridState extends State<_Grid> {
  final ScrollController _vMain = ScrollController();
  final ScrollController _vLeft = ScrollController();
  final ScrollController _hMain = ScrollController();
  final ScrollController _hTop = ScrollController();

  bool _syncV = false;
  bool _syncH = false;

  @override
  void initState() {
    super.initState();

    _vMain.addListener(() {
      if (_syncV) return;
      _syncV = true;
      _vLeft.jumpTo(_vMain.offset);
      _syncV = false;
    });

    _hMain.addListener(() {
      if (_syncH) return;
      _syncH = true;
      _hTop.jumpTo(_hMain.offset);
      _syncH = false;
    });
  }

  String _formatDate(String isoDate) {
    final p = isoDate.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}' : isoDate;
  }

  @override
  void dispose() {
    _vMain.dispose();
    _vLeft.dispose();
    _hMain.dispose();
    _hTop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.c.days();
    final students = widget.c.students;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Attendance Grid',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Excel',
            onPressed: () async {
              await widget.c.exportExcel();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Excel file exported successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              /// ================= MAIN GRID =================
              Positioned(
                top: 46,
                left: 80,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  controller: _vMain,
                  physics: const FastScrollPhysics(),
                  child: SingleChildScrollView(
                    controller: _hMain,
                    physics: const FastScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: List.generate(students.length, (row) {
                        final stats =
                            widget.c.studentStats(students[row]);
                        final isAlt = row.isOdd;

                        return Row(
                          children: [
                            ...stats.daily.map(
                              (v) => _cell(v, alt: isAlt),
                            ),
                            _cell(
                              stats.total,
                              isTotal: true,
                              alt: isAlt,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),

              /// ================= TOP HEADER =================
              Positioned(
                top: 0,
                left: 80,
                right: 0,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: _hTop,
                    physics: const FastScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...days.map(
                          (d) => _headerCell(_formatDate(d)),
                        ),
                        _headerCell('Total', isTotal: true),
                      ],
                    ),
                  ),
                ),
              ),

              /// ================= LEFT ROLL NUMBERS =================
              Positioned(
                top: 46,
                left: 0,
                width: 80,
                bottom: 0,
                child: SingleChildScrollView(
                  controller: _vLeft,
                  physics: const FastScrollPhysics(),
                  child: Column(
                    children: List.generate(students.length, (i) {
                      return _rollCell(
                        students[i],
                        alt: i.isOdd,
                      );
                    }),
                  ),
                ),
              ),

              /// ================= TOP-LEFT CORNER =================
              Positioned(
                top: 0,
                left: 0,
                width: 80,
                height: 46,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Roll',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // CELL STYLES
  // ===============================================================
  Widget _cell(String text,
      {bool isTotal = false, bool alt = false}) {
    return Container(
      width: 60,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTotal
            ? Colors.blue.shade50
            : alt
                ? const Color(0xFFF8FAFF)
                : Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.blue.shade800 : Colors.black87,
        ),
      ),
    );
  }

  Widget _headerCell(String text, {bool isTotal = false}) {
    return Container(
      width: 60,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTotal ? Colors.blue.shade100 : Colors.blue.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _rollCell(String text, {bool alt = false}) {
    return Container(
      width: 80,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: alt ? const Color(0xFFF8FAFF) : Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}