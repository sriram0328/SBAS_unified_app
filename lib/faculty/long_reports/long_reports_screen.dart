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

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LongReportsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Attendance')),

      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                children: [
                  _selectors(c),
                ],
              ),
            ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.table_chart),
          label: const Text('View Attendance'),
          onPressed: () async {
            final ok = await c.loadReport();
            if (!context.mounted) return;

            if (ok) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _Grid(c),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No data found')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _selectors(LongReportsController c) {
    Widget drop(
      String label,
      String? value,
      List<String> items,
      void Function(String?) onChanged,
    ) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      );
    }

    return Column(
      children: [
        drop('Year', c.year, ['1', '2', '3', '4'], (v) => c.year = v),
        drop('Branch', c.branch, ['AIML', 'AIDS'], (v) => c.branch = v),
        drop('Section', c.section, ['A', 'B'], (v) => c.section = v),
        drop('Subject', c.subject, ['23AM4T03'], (v) => c.subject = v),
        drop('Month', c.month, ['2026-01', '2026-02'], (v) => c.month = v),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  final LongReportsController c;
  const _Grid(this.c);

  @override
  Widget build(BuildContext context) {
    final days = c.days();
    final students = c.students;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Grid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () async {
              await c.exportPdf();
            },
          ),
        ],
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _cell('Roll'),
                    ...days.map((d) => _cell(d.split('-').last)),
                    _cell('Total'),
                  ],
                ),
                ...students.map((r) {
                  final s = c.studentStats(r);
                  return Row(
                    children: [
                      _cell(r),
                      ...s.daily.map(_cell),
                      _cell(s.total),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(String t) {
    return Container(
      width: 55,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        t,
        style: const TextStyle(fontSize: 10),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
