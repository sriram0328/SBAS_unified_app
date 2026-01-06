import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/session.dart';
import 'faculty_setup_controller.dart';
import '../scanner/live_scanner_screen.dart';

class FacultySetupScreen extends StatelessWidget {
  const FacultySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FacultySetupController(),
      child: const _FacultySetupView(),
    );
  }
}

class _FacultySetupView extends StatelessWidget {
  const _FacultySetupView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FacultySetupController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FacultySetupScreen()),
              );
            },
          ),
        ],
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : c.errorMessage != null
              ? _ErrorView(
                  message: c.errorMessage!,
                  onRetry: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const FacultySetupScreen()),
                    );
                  },
                )
              : _MainContent(c),
    );
  }
}

/* -------------------------------------------------------------------------- */

class _MainContent extends StatelessWidget {
  final FacultySetupController c;
  const _MainContent(this.c);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Class Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          _buildDropdown(
            label: '1. Subject',
            icon: Icons.book,
            value: c.selectedSubjectName,
            items: c.availableSubjects.toList()..sort(),
            enabled: true,
            onChanged: (v) { if (v != null) c.selectSubject(v); },
          ),

          const SizedBox(height: 16),

          _buildDropdown(
            label: '2. Year',
            icon: Icons.calendar_today,
            value: c.selectedYear,
            items: c.getAvailableYears().toList()..sort(),
            enabled: c.selectedSubjectName != null,
            onChanged: (v) { if (v != null) c.selectYear(v); },
          ),

          const SizedBox(height: 16),

          _buildDropdown(
            label: '3. Branch',
            icon: Icons.account_tree,
            value: c.selectedBranch,
            items: c.getAvailableBranches().toList()..sort(),
            enabled: c.selectedYear != null,
            onChanged: (v) { if (v != null) c.selectBranch(v); },
          ),

          const SizedBox(height: 16),

          _buildDropdown(
            label: '4. Section',
            icon: Icons.group,
            value: c.selectedSection,
            items: c.getAvailableSections().toList()..sort(),
            enabled: c.selectedBranch != null,
            onChanged: (v) { if (v != null) c.selectSection(v); },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          const Text('5. Select Period'),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            children: c.periods.map((p) {
              return ChoiceChip(
                label: Text('Period $p'),
                selected: c.selectedPeriodNumber == p,
                onSelected: (_) => c.setPeriodNumber(p),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: c.canProceed
                  ? () => _handleProceed(context, c)
                  : null,
              child: const Text('Proceed to Scan QR Codes'),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */

Widget _buildDropdown({
  required String label,
  required IconData icon,
  required String? value,
  required List<String> items,
  required bool enabled,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    ),
    items: items
        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
        .toList(),
    onChanged: enabled ? onChanged : null,
    isExpanded: true,
  );
}

/* -------------------------------------------------------------------------- */

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */

Future<void> _handleProceed(
  BuildContext context,
  FacultySetupController c,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  await c.loadEnrolledStudents();

  if (!context.mounted) return;
  Navigator.pop(context);

  if (c.errorMessage != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(c.errorMessage!)));
    return;
  }

  if (c.enrolledStudentRollNos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No enrolled students found')),
    );
    return;
  }

 Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => LiveScannerScreen(
      facultyId: Session.facultyId,
      periodNumber: c.selectedPeriodNumber, // ✅ FIXED
      year: c.selectedYear!,
      branch: c.selectedBranch!,
      section: c.selectedSection!,
      subjectCode: c.subjectCode,
      subjectName: c.subjectName,
      enrolledStudentIds: c.enrolledStudentRollNos,
    ),
  ),
);
}