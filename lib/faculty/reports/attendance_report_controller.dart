class AttendanceReportController {
  // ---------------------------
  // Selected Filters (Navbar)
  // ---------------------------
  String selectedDate = "Wed, 17 Dec 2025";
  String subject = "ML (20AM5T02)";
  String section = "A";
  String year = "4th Year";
  String branch = "AIML";

  // ---------------------------
  // Dropdown Options
  // ---------------------------
  final List<String> availableDates = [
    "Wed, 17 Dec 2025",
    "Tue, 16 Dec 2025",
    "Mon, 15 Dec 2025",
  ];

  final List<String> availableSubjects = [
    "ML (20AM5T02)",
    "DL (20AM5T03)",
    "ML LAB (23AM4L06)",
  ];

  final List<String> availableSections = ["A", "B", "C"];
  final List<String> availableYears = [
    "1st Year",
    "2nd Year",
    "3rd Year",
    "4th Year",
  ];
  final List<String> availableBranches = [
    "AIML",
    "CSE",
    "ECE",
  ];

  // ---------------------------
  // Attendance Stats
  // ---------------------------
  int totalStudents = 0;
  int presentCount = 0;
  int absentCount = 0;

  // ---------------------------
  // Current Student List
  // ---------------------------
  List<AttendanceStudent> students = [];

  // ---------------------------
  // 🔥 DUMMY BACKEND DATA
  // Key format:
  // Date|Subject|Section
  // ---------------------------
  final Map<String, List<AttendanceStudent>> _attendanceData = {
    "Wed, 17 Dec 2025|ML (20AM5T02)|A": [
      AttendanceStudent("22ML01", "Haarthi", true),
      AttendanceStudent("22ML02", "Likhitha", true),
      AttendanceStudent("22ML03", "Rakesh", false),
      AttendanceStudent("22ML04", "Uttej", true),
      AttendanceStudent("22ML05", "Sriram", false),
    ],

    "Tue, 16 Dec 2025|ML (20AM5T02)|A": [
      AttendanceStudent("22ML01", "Haarthi", false),
      AttendanceStudent("22ML02", "Likhitha", true),
      AttendanceStudent("22ML03", "Rakesh", true),
      AttendanceStudent("22ML04", "Uttej", true),
      AttendanceStudent("22ML05", "Sriram", true),
    ],

    "Mon, 15 Dec 2025|ML LAB (23AM4L06)|C": [
      AttendanceStudent("22ML31", "Tejas", true),
      AttendanceStudent("22ML32", "Sriram", true),
      AttendanceStudent("22ML33", "Pavani", true),
    ],

    "Wed, 17 Dec 2025|DL (20AM5T03)|B": [
      AttendanceStudent("22DL11", "Ananya", true),
      AttendanceStudent("22DL12", "Rahul", false),
      AttendanceStudent("22DL13", "Kiran", true),
      AttendanceStudent("22DL14", "Meghana", true),
    ],
  };

  // ---------------------------
  // Constructor
  // ---------------------------
  AttendanceReportController() {
    _reloadAttendanceData();
  }

  // ---------------------------
  // Computed Lists
  // ---------------------------
  List<AttendanceStudent> get presentStudents =>
      students.where((s) => s.isPresent).toList();

  List<AttendanceStudent> get absentStudents =>
      students.where((s) => !s.isPresent).toList();

  // ---------------------------
  // Update Filters (Navbar)
  // ---------------------------
  void updateFilters({
    String? date,
    String? subjectValue,
    String? sectionValue,
    String? yearValue,
    String? branchValue,
  }) {
    if (date != null) selectedDate = date;
    if (subjectValue != null) subject = subjectValue;
    if (sectionValue != null) section = sectionValue;
    if (yearValue != null) year = yearValue;
    if (branchValue != null) branch = branchValue;

    _reloadAttendanceData();
  }

  // ---------------------------
  // Reload Data (FAKE API)
  // ---------------------------
  void _reloadAttendanceData() {
    final key = "$selectedDate|$subject|$section";

    students = _attendanceData[key] ?? [];

    totalStudents = students.length;
    presentCount = presentStudents.length;
    absentCount = absentStudents.length;
  }

  // ---------------------------
  // CSV Export
  // ---------------------------
  String generateCSV() {
    final buffer = StringBuffer();

    buffer.writeln("Attendance Report");
    buffer.writeln("Date,$selectedDate");
    buffer.writeln("Subject,$subject");
    buffer.writeln("Class,$branch $year Section $section");
    buffer.writeln("Total,$totalStudents");
    buffer.writeln("Present,$presentCount");
    buffer.writeln("Absent,$absentCount");
    buffer.writeln("");
    buffer.writeln("Roll No,Name,Status");

    for (final s in students) {
      buffer.writeln(
          "${s.rollNo},${s.name},${s.isPresent ? "Present" : "Absent"}");
    }

    return buffer.toString();
  }

  // ---------------------------
  // Shareable Text Report
  // ---------------------------
  String generateTextReport() {
    final buffer = StringBuffer();

    buffer.writeln("ATTENDANCE REPORT");
    buffer.writeln("-----------------");
    buffer.writeln("Date : $selectedDate");
    buffer.writeln("Subject : $subject");
    buffer.writeln("Class : $branch $year Section $section");
    buffer.writeln("");
    buffer.writeln("Total : $totalStudents");
    buffer.writeln("Present : $presentCount");
    buffer.writeln("Absent : $absentCount");
    buffer.writeln("");
    buffer.writeln("PRESENT STUDENTS:");

    for (final s in presentStudents) {
      buffer.writeln("✓ ${s.rollNo} - ${s.name}");
    }

    if (absentStudents.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("ABSENT STUDENTS:");
      for (final s in absentStudents) {
        buffer.writeln("✗ ${s.rollNo} - ${s.name}");
      }
    }

    return buffer.toString();
  }
}

// ---------------------------
// Model
// ---------------------------
class AttendanceStudent {
  final String rollNo;
  final String name;
  final bool isPresent;

  AttendanceStudent(this.rollNo, this.name, this.isPresent);
}
