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
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Setup Attendance', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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

class _MainContent extends StatelessWidget {
  final FacultySetupController c;
  const _MainContent(this.c);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Initialize Class',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E)),
          ),
          const SizedBox(height: 24),
          
          _buildStepLabel('1', 'SELECT CLASS DETAILS'),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'Subject',
            icon: Icons.book_outlined,
            value: c.selectedSubjectName,
            items: c.availableSubjects.toList()..sort(),
            enabled: true,
            onChanged: (v) { if (v != null) c.selectSubject(v); },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Year',
                  icon: Icons.school_outlined,
                  value: c.selectedYear,
                  items: c.getAvailableYears().toList()..sort(),
                  enabled: c.selectedSubjectName != null,
                  onChanged: (v) { if (v != null) c.selectYear(v); },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Branch',
                  icon: Icons.business_center_outlined,
                  value: c.selectedBranch,
                  items: c.getAvailableBranches().toList()..sort(),
                  enabled: c.selectedYear != null,
                  onChanged: (v) { if (v != null) c.selectBranch(v); },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Section',
            icon: Icons.group_outlined,
            value: c.selectedSection,
            items: c.getAvailableSections().toList()..sort(),
            enabled: c.selectedBranch != null,
            onChanged: (v) { if (v != null) c.selectSection(v); },
          ),

          const SizedBox(height: 32),
          _buildStepLabel('2', 'SELECT PERIOD'),
          const SizedBox(height: 16),
          _buildPeriodGrid(), // New Grid Layout for Periods

          const SizedBox(height: 40),
          _buildProceedButton(context),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String step, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(step, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: DropdownButtonFormField<String>(
        initialValue: (items.contains(value)) ? value : null,
        isExpanded: true,
        style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Colors.blueGrey),
          prefixIcon: Icon(icon, size: 20, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildPeriodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: c.periods.length,
      itemBuilder: (context, index) {
        final p = c.periods[index];
        bool isSelected = c.selectedPeriodNumber == p;
        return GestureDetector(
          onTap: () => c.setPeriodNumber(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: isSelected 
                ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 16,
                  color: isSelected ? Colors.white70 : Colors.blueGrey.shade200,
                ),
                const SizedBox(height: 4),
                Text(
                  'P$p',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1A1C1E),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProceedButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: c.canProceed 
            ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
            : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2962FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        onPressed: c.canProceed ? () => _handleProceed(context, c) : null,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Proceed to Scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade400),
            ),
            const SizedBox(height: 24),
            const Text('Initialization Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: Colors.blueAccent.shade700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onRetry, 
                child: const Text('Retry Setup')
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleProceed(BuildContext context, FacultySetupController c) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  await c.loadEnrolledStudents();

  if (!context.mounted) return;
  Navigator.pop(context);

  if (c.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(c.errorMessage!)));
    return;
  }

  if (c.enrolledStudentRollNos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No enrolled students found for this section')),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LiveScannerScreen(
        facultyId: Session.facultyId,
        periodNumber: c.selectedPeriodNumber,
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