class TimetableController {
  final Map<String, List<TimetablePeriod>> timetable = {
    "Monday": [
      TimetablePeriod(
        subjectName: "ML LAB",
        subjectCode: "23AM4L06",
        periodNumber: 2,
        startTime: "10:00",
        endTime: "11:00",
        branch: "AIML",
        year: "II",
        section: "A",
      ),
      TimetablePeriod(
        subjectName: "ML LAB",
        subjectCode: "23AM4L06",
        periodNumber: 3,
        startTime: "11:10",
        endTime: "12:10",
        branch: "AIML",
        year: "II",
        section: "A",
      ),
    ],
    "Tuesday": [
      TimetablePeriod(
        subjectName: "Machine Learning",
        subjectCode: "23AM4T03",
        periodNumber: 1,
        startTime: "09:00",
        endTime: "10:00",
        branch: "AIML",
        year: "II",
        section: "A",
      ),
    ],
    "Wednesday": [
      TimetablePeriod(
        subjectName: "Machine Learning",
        subjectCode: "23AM4T03",
        periodNumber: 6,
        startTime: "15:00",
        endTime: "16:00",
        branch: "AIML",
        year: "II",
        section: "A",
      ),
    ],
  };
}

class TimetablePeriod {
  final String subjectName;
  final String subjectCode;
  final int periodNumber;
  final String startTime;
  final String endTime;
  final String branch;
  final String year;
  final String section;

  TimetablePeriod({
    required this.subjectName,
    required this.subjectCode,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    required this.branch,
    required this.year,
    required this.section,
  });
}
