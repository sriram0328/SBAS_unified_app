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
      child: const _LongReportsSelectionView(),
    );
  }
}

class _LongReportsSelectionView extends StatelessWidget {
  const _LongReportsSelectionView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<LongReportsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Report Parameters'), centerTitle: true),
      body: ctrl.isLoading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(child: ListView(children: [
              _drop("Year", ctrl.selectedYear, ctrl.years, ctrl.setYear),
              _drop("Branch", ctrl.selectedBranch, ctrl.branches, ctrl.setBranch),
              _drop("Section", ctrl.selectedSection, ctrl.sections, ctrl.setSection),
              _drop("Subject", ctrl.selectedSubject, ctrl.subjects.map((e) => e['code'] as String).toList(), ctrl.setSubject),
              _drop("Month", ctrl.selectedMonth, ctrl.months, ctrl.setMonth),
            ])),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              onPressed: ctrl.canGenerate ? () async {
                if (await ctrl.fetchReportData() && context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => _SyncedReportView(controller: ctrl)));
                }
              } : null,
              child: const Text("View Tabular Report"),
            ))
          ],
        ),
      ),
    );
  }

  Widget _drop(String l, String? v, List<String> i, Function(String?) f) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: l, border: const OutlineInputBorder()),
      value: v, items: i.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: f,
    ));
  }
}

class _SyncedReportView extends StatefulWidget {
  final LongReportsController controller;
  const _SyncedReportView({required this.controller});
  @override
  State<_SyncedReportView> createState() => _SyncedReportViewState();
}

class _SyncedReportViewState extends State<_SyncedReportView> {
  final ScrollController _fixedC = ScrollController(), _mainC = ScrollController();

  @override
  void initState() {
    super.initState();
    _mainC.addListener(() { if (_fixedC.offset != _mainC.offset) _fixedC.jumpTo(_mainC.offset); });
    _fixedC.addListener(() { if (_mainC.offset != _fixedC.offset) _mainC.jumpTo(_fixedC.offset); });
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.controller.getDaysInMonth();
    final dTotals = widget.controller.calculateDailyClassTotals();
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Grid'), actions: [IconButton(icon: const Icon(Icons.print), onPressed: widget.controller.printReport)]),
      body: Row(children: [
        SizedBox(width: 90, child: Column(children: [
          _cell("Roll No", isH: true, w: 90),
          Expanded(child: ListView.builder(controller: _fixedC, itemCount: widget.controller.attendanceData.length, itemBuilder: (c, i) => _cell(widget.controller.attendanceData[i]['rollNo'], w: 90))),
          _cell("Total", isH: true, w: 90, color: Colors.orange.shade100),
        ])),
        Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: days.length * 45.0 + 70.0, child: Column(children: [
          Row(children: [...days.map((d) => _cell(d.split('-').last, isH: true, w: 45)), _cell("Total", isH: true, w: 70)]),
          Expanded(child: ListView.builder(controller: _mainC, itemCount: widget.controller.attendanceData.length, itemBuilder: (c, i) {
            final stats = widget.controller.calculateStudentStats(widget.controller.attendanceData[i]);
            return Row(children: [...stats.dailyStrings.map((s) => _cell(s, w: 45)), _cell(stats.totalString, w: 70, tC: Colors.blue)]);
          })),
          Row(children: [...days.map((d) => _cell(dTotals[d]!, isH: true, w: 45, color: Colors.orange.shade50)), _cell("-", isH: true, w: 70, color: Colors.orange.shade50)]),
        ]))))
      ]),
    );
  }

  Widget _cell(String t, {bool isH = false, required double w, Color? tC, Color? color}) {
    return Container(width: w, height: 35, alignment: Alignment.center, decoration: BoxDecoration(color: color ?? (isH ? Colors.blue.shade50 : Colors.white), border: Border.all(color: Colors.grey.shade300)), child: Text(t, style: TextStyle(fontSize: 10, fontWeight: isH ? FontWeight.bold : FontWeight.normal, color: tC)));
  }
}