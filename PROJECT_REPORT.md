# SBAS (Smart Building Attendance System) - Project Report
**Date**: January 16, 2026  
**Project Name**: sbas_attendance  
**Platform**: Flutter (Cross-platform Mobile Application)  
**Version**: 1.0.0+1

---

## 📋 Executive Summary

SBAS Attendance is a comprehensive Flutter-based attendance management system designed for educational institutions. It streamlines attendance tracking, reporting, and management through dual-role dashboards for students and faculty members. The system leverages Firebase for backend services and real-time data synchronization, with barcode scanning capabilities for efficient attendance marking.

---

## 🎯 Project Overview

### Purpose
The application addresses the need for a modern, efficient attendance management system in educational institutions by:
- **Students**: View personal attendance records, generate ID cards with barcodes, and track attendance trends
- **Faculty**: Conduct attendance via barcode scanning, manage timetables, and generate comprehensive attendance reports
- **Administration**: Monitor system-wide attendance patterns and compliance

### Key Features
✅ **Authentication**: Role-based login (Student/Faculty)  
✅ **Dual Dashboards**: Separate interfaces for students and faculty  
✅ **Barcode Scanning**: Real-time attendance marking via mobile camera  
✅ **Attendance Tracking**: Multiple views (daily, weekly, monthly)  
✅ **ID Card Generation**: Digital student ID cards with barcodes  
✅ **Reporting**: Comprehensive attendance reports with filters  
✅ **Timetable Management**: Faculty timetable viewing and scheduling  
✅ **Real-time Sync**: Cloud Firestore for live data updates  

---

## 🏗️ Architecture Overview

### Technology Stack

| Category | Technology | Version |
|----------|-----------|---------|
| **Framework** | Flutter | 3.10.4 SDK |
| **Language** | Dart | 3.10.4+ |
| **Backend** | Firebase | Multiple services |
| **Auth** | Firebase Auth | 5.3.4 |
| **Database** | Cloud Firestore | 5.5.1 |
| **Barcode Scanner** | mobile_scanner | 5.2.3 |
| **Barcode Generator** | barcode_widget | 2.0.4 |
| **PDF Export** | pdf | 3.10.6 |
| **CSV Export** | csv | 6.0.0 |
| **State Management** | Provider | 6.1.0 |
| **HTTP Requests** | http | 1.2.2 |
| **Date Formatting** | intl | 0.19.0 |
| **Storage** | shared_preferences | 2.2.2 |

### Project Structure

```
lib/
├── main.dart                          # App entry point with Firebase initialization
├── splashscreen.dart                  # Splash/Loading screen
├── app.dart                           # App configuration (empty)
├── firebase_options.dart              # Firebase configuration
│
├── auth/                              # Authentication module
│   ├── login/
│   │   ├── login_screen.dart         # Login UI with autofill support
│   │   ├── login_controller.dart     # Login state management
│   │   └── login_service.dart        # Login service integration
│   └── role_router.dart              # Route users to appropriate dashboard
│
├── core/                              # Core utilities and constants
│   ├── colors.dart                   # Color theme definitions
│   ├── session.dart                  # Session/Global state (facultyId)
│   ├── constants/                    # App constants
│   ├── theme/                        # Theme configuration
│   └── utils/                        # Utility functions
│
├── models/                            # Data models
│   ├── user_model.dart               # Base user model
│   ├── student_model.dart            # Student-specific model
│   ├── faculty_model.dart            # Faculty-specific model
│   ├── attendance_model.dart         # Attendance records & sessions
│   └── subject_model.dart            # Subject information
│
├── services/                          # Firebase & Business Logic Services
│   ├── firebase_auth_service.dart    # Authentication service
│   ├── firestore_service.dart        # Firestore data operations
│   └── attendance_service.dart       # Attendance data queries
│
├── student/                           # Student Module
│   ├── student_shell.dart            # Student app shell (navigation)
│   ├── dashboard/
│   │   ├── student_dashboard_screen.dart
│   │   └── student_dashboard_controller.dart
│   ├── attendance/
│   │   ├── attendance_overview_screen.dart
│   │   ├── attendance_overview_controller.dart
│   │   ├── attendance_history_screen.dart
│   │   ├── daily/
│   │   ├── weekly/
│   │   └── monthly/
│   ├── id_card/
│   │   ├── student_id_screen.dart
│   │   └── student_id_controller.dart
│   └── profile/
│       ├── student_profile_screen.dart
│       └── student_profile_controller.dart
│
├── faculty/                           # Faculty Module
│   ├── faculty_shell.dart            # Faculty app shell (navigation)
│   ├── dashboard/
│   │   ├── faculty_dashboard_screen.dart
│   │   └── faculty_dashboard_controller.dart
│   ├── scanner/
│   │   ├── live_scanner_screen.dart
│   │   └── scanner_controller.dart
│   ├── reports/
│   │   ├── attendance_report_screen.dart
│   │   └── attendance_report_controller.dart
│   ├── timetable/
│   │   └── timetable_screen.dart
│   └── setup/                        # Faculty setup/initialization
│
└── assets/                            # Static assets
    ├── icon/
    │   └── app_icon.png
    └── a.txt
```

### Architectural Patterns

#### 1. **MVC-Style Architecture**
- **Models**: Data structures (StudentModel, FacultyModel, AttendanceRecord)
- **Views**: UI screens (LoginScreen, StudentDashboardScreen, etc.)
- **Controllers**: State management and business logic (LoginController, StudentDashboardController)

#### 2. **Service Layer**
- `FirebaseAuthService`: Handles authentication operations
- `FirestoreService`: Manages Firestore CRUD operations
- `AttendanceService`: Specialized queries for attendance data

#### 3. **Role-Based Routing**
```
Login Screen
    ↓
Validate Credentials (via LoginService)
    ↓
Role Router (checks role field)
    ├→ Student Role → StudentShell (4-tab navigation)
    └→ Faculty Role → FacultyShell (3-tab navigation)
```

#### 4. **State Management**
- **ChangeNotifier**: Used in controllers for state updates
- **Provider Pattern**: Declared in pubspec.yaml (available but not heavily utilized in current code)
- **Manual Listeners**: Login and other controllers use ChangeNotifier

---

## 🔐 Authentication & Security

### Login Flow

```
┌─────────────────┐
│  LoginScreen    │
│   (UI Layer)    │
└────────┬────────┘
         │
         ↓
┌─────────────────────────┐
│  LoginController        │
│  - Manages state        │
│  - Notifies listeners   │
└────────┬────────────────┘
         │
         ↓
┌──────────────────────────────────┐
│  LoginService                    │
│  - Calls backend auth server     │
│  - Exchanges credentials for     │
│    Firebase custom token         │
└────────┬─────────────────────────┘
         │
         ↓
┌──────────────────────────────────┐
│  Auth Server (http://localhost:9002)
│  - Verifies credentials          │
│  - Issues custom JWT token       │
└────────┬─────────────────────────┘
         │
         ↓
┌──────────────────────────────────┐
│  Firebase Auth                   │
│  - Validates custom token        │
│  - Signs in user                 │
│  - Returns Firebase User object  │
└────────┬─────────────────────────┘
         │
         ↓
┌──────────────────────────────────┐
│  Firestore Fetch                 │
│  - Retrieves user profile        │
│  - Gets role and metadata        │
└────────┬─────────────────────────┘
         │
         ↓
┌──────────────────────────────────┐
│  RoleRouter                      │
│  - Routes to appropriate shell   │
│  - StudentShell or FacultyShell  │
└──────────────────────────────────┘
```

### Security Features
- **Custom Token Authentication**: Backend issues custom tokens instead of direct credential storage
- **Firebase Security Rules**: Permissive dev rules included (needs production hardening)
- **Role-Based Access Control**: Users redirected based on Firestore role field
- **Autofill Support**: Secure password management with OS integration

### Key Security Considerations
⚠️ **Development-Only Rules**: `firestore.rules.dev` is permissive for testing  
⚠️ **Production**: Must implement strict Firestore rules restricting reads by user role  
✅ **Recommended Flow**: 
1. Verify credentials on trusted backend
2. Issue custom token with role claims
3. Client uses token for Firebase sign-in
4. Enforce rules server-side

---

## 📱 Student Dashboard Workflow

### Overview
The student module provides a comprehensive view of attendance and academic information.

### Student Shell Navigation
```
┌─────────────────────────────────────────────────┐
│  StudentShell (Bottom Navigation - 4 Tabs)      │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────┐ ┌──────┐ ┌───────────┐ ┌────────┐
│  │  Home    │ │ ID   │ │ Attendance│ │Profile │
│  │ (Index 0)│ │(idx 1)│ │ (Index 2) │ │(idx 3) │
│  └──────────┘ └──────┘ └───────────┘ └────────┘
│
└─────────────────────────────────────────────────┘
```

### 1. Dashboard Tab (StudentDashboardScreen)

**Functionality:**
- Displays personalized welcome message
- Shows key metrics:
  - Student name and roll number
  - Branch/Department information
  - Section assignment
  - Year of study
  - **Real-time Attendance Percentage**

**Data Flow:**
```
StudentDashboardScreen
    ↓
StudentDashboardController.loadStudentData()
    ├→ Fetch from 'students' collection (uid)
    │   - name, rollno, branch, section
    │
    ├→ Fetch from 'academic_records' collection
    │   - yearOfStudy (where status='active')
    │
    └→ _calculateAttendance()
        ├→ Query 'attendance' collection
        │   where: enrolledStudentIds contains rollNo
        │
        ├→ Count:
        │   - totalClasses (enrolledStudentIds count)
        │   - presentCount (presentStudentIds count)
        │
        └→ Calculate: (presentCount / totalClasses) * 100
```

**Key Calculation Logic:**
```dart
// Only count attendance where student is enrolled
if (enrolledList.contains(rollNo)) {
  totalClasses++;
  if (presentList.contains(rollNo)) {
    presentCount++;
  }
}
attendancePercentage = (presentCount / totalClasses) * 100;
```

### 2. ID Card Tab (StudentIdScreen)

**Functionality:**
- Generates digital student ID card
- Displays barcode (roll number encoded)
- Shows student photo/profile image
- Allows barcode export/sharing

**Barcode Generation:**
```
StudentModel.barcodeData
    ↓ (Uses roll number)
barcode_widget: ^2.0.4
    ↓
BarcodeWidget generates visual barcode
    ↓
share_plus: ^10.1.2 (Export/Share capability)
```

### 3. Attendance Tab (AttendanceOverviewScreen)

**Multiple Views Available:**

#### a) **Overview View** (AttendanceOverviewScreen)
- Attendance percentage summary
- Subject-wise breakdown
- Overall statistics
- Quick navigation to detailed views

#### b) **Daily View** (daily/)
- Attendance for specific date
- Period-wise attendance
- Subject information
- Time stamps

#### c) **Weekly View** (weekly/)
- 7-day attendance summary
- Attendance trends
- Absence patterns
- Weekly percentage calculation

#### d) **Monthly View** (monthly/)
- Month-long attendance data
- Day-by-day breakdown
- Holiday adjustments
- Monthly statistics

**Data Fetching for Attendance:**
```
AttendanceService Methods:

1. getAttendanceForStudentRoll(rollNo)
   └→ Query attendance collection
      - where: enrolledStudentIds contains rollNo
      - orderBy: timestamp DESC
      - Returns: Last 100 records

2. getAttendanceByDate(rollNo, date)
   └→ Query for specific date
      - where: date = specified date
      - where: enrolledStudentIds contains rollNo

3. getAttendanceInRange(rollNo, startDate, endDate)
   └→ Date range queries
      - where: enrolledStudentIds contains rollNo
      - where: date >= startDate
      - where: date <= endDate
      - orderBy: date, periodNumber

4. getSubjectWiseAttendance(rollNo)
   └→ Aggregate attendance by subject
      - Calculate per-subject attendance %
      - Total classes vs. attended
```

### 4. Profile Tab (StudentProfileScreen)

**Displays:**
- Full student information
- Contact details
- Department and academic details
- Enrolled subjects list
- Edit profile option (if applicable)

---

## 👨‍🏫 Faculty Dashboard Workflow

### Overview
The faculty module provides tools for attendance marking, scheduling, and reporting.

### Faculty Shell Navigation
```
┌─────────────────────────────────────────────┐
│  FacultyShell (Bottom Navigation - 3 Tabs)  │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐    │
│  │Dashboard│  │Timetable│  │Reports  │    │
│  │ (idx 0) │  │ (idx 1) │  │ (idx 2) │    │
│  └─────────┘  └─────────┘  └─────────┘    │
│                                             │
└─────────────────────────────────────────────┘
```

### 1. Dashboard Tab (FacultyDashboardScreen)

**Functionality:**
- Faculty profile display:
  - Faculty name
  - Faculty ID/Code
  - Department
  - Today's date (formatted)
  
- **Today's Classes Widget:**
  - Number of classes today
  - List of all classes with:
    - Subject name and code
    - Time
    - Location
    - Class size (enrolled students)
  - Quick action buttons for attendance marking

**Data Loading:**
```
FacultyDashboardController.load()
    │
    ├→ _loadFacultyProfile()
    │   └→ Query 'faculty' collection (doc = facultyId)
    │       - name, facultyId, department
    │
    └→ _loadTodayClasses()
        └→ Query 'faculty_timetables' (doc = facultyId)
            ├→ Get current day (e.g., "monday")
            └→ Extract classes from timetable
                - Subject details
                - Time slots
                - Room/location
                - Student count
```

### 2. Timetable Tab (TimetableScreen)

**Functionality:**
- Displays faculty's weekly timetable
- Shows scheduled classes by day and period
- Subject and room information
- Enrolled student count per class

**Data Structure:**
```
Collection: faculty_timetables
Document: {facultyId}
Structure:
{
  facultyId: "FAC123",
  monday: [
    {
      period: 1,
      subject: "Data Structures",
      code: "CS201",
      room: "A101",
      startTime: "09:00",
      endTime: "10:00",
      students: 45
    }
  ],
  tuesday: [...],
  ...
  sunday: [...]
}
```

### 3. Reports Tab (AttendanceReportScreen)

**Comprehensive Reporting Features:**

#### a) **Filtering System**
```
Filter Options:
├── Date (yyyy-MM-dd)
├── Subject (name + code)
├── Branch
├── Year
├── Section
└── Period Number
```

#### b) **Data View**
```
Report Display:
├── Statistics Pills
│   ├── Total Students Marked
│   ├── Present Count
│   └── Absent Count
│
├── Filter Toggles
│   ├── All (show all records)
│   ├── Present (filter to marked present)
│   └── Absent (filter to unmarked)
│
└── Detailed Table
    └── Student Roll Numbers with presence status
```

#### c) **Report Generation**
```
AttendanceReportController.initialize()
    │
    ├→ Query 'attendance' collection
    │   where: facultyId == current faculty
    │
    ├→ Extract unique values for filters:
    │   ├── Dates (from timestamp)
    │   ├── Subjects (subjectCode, subjectName)
    │   ├── Branches
    │   ├── Years
    │   ├── Sections
    │   └── Periods
    │
    └→ Load report data
        ├→ Query filtered attendance
        ├→ Parse student presence
        └→ Generate statistics
```

**Data Export:**
- PDF generation capability (pdf: ^3.10.6)
- CSV export support (csv: ^6.0.0)
- Printable reports

---

## 📊 Attendance Marking & Barcode System

### Scanner Workflow (Faculty Perspective)

```
┌──────────────────────────────────────┐
│  Faculty Opens Live Scanner Screen   │
└────────────┬─────────────────────────┘
             │
             ↓
┌──────────────────────────────────────┐
│  Scanner loads attendance session:   │
│  - Reads QR parameters               │
│  - Initializes barcode scanner       │
└────────────┬─────────────────────────┘
             │
             ↓
┌──────────────────────────────────────┐
│  mobile_scanner: ^5.2.3              │
│  - Activates camera                  │
│  - Captures barcode data             │
│  - Decodes to student ID             │
└────────────┬─────────────────────────┘
             │
             ↓
┌──────────────────────────────────────┐
│  ScannerController.onStudentScanned()│
│  - Validates student enrollment      │
│  - Checks for duplicates             │
└────────────┬─────────────────────────┘
             │
             ↓
┌──────────────────────────────────────┐
│  Add to Present Set                  │
│  - Update UI count                   │
│  - Show success popup (2 sec)        │
└────────────┬─────────────────────────┘
             │
             ↓
┌──────────────────────────────────────┐
│  Faculty confirms & submits          │
│  - Saves to 'attendance' collection  │
└──────────────────────────────────────┘
```

### Barcode/QR Code System

#### Student Side (ID Generation)
```
StudentModel
    │
    ├── barcodeData: rollNumber
    ├── barcodeId: studentId
    │
    └→ barcode_widget renders:
       - CODE128 or QR code
       - Encodes roll number
       - Embedded in ID card
```

#### Faculty Side (Scanning)
```
live_scanner_screen.dart
    │
    ├→ Uses mobile_scanner
    ├→ Decodes barcode → studentId/rollNumber
    ├→ Validates against enrolledStudentIds
    │
    └→ If valid:
       └→ Add to presentStudentIds set
         - Update count
         - Highlight scanned
         - Prevent duplicates
```

### Attendance Record Structure

```dart
Collection: attendance
Documents per class session:
{
  id: "session_123",
  facultyId: "FAC001",
  subjectCode: "CS201",
  subjectName: "Data Structures",
  date: "2024-01-16",  // ISO format: YYYY-MM-DD
  timestamp: Timestamp(datetime),
  
  // Academic filters
  branch: "Computer Science",
  year: "2",
  section: "A",
  periodNumber: 1,
  
  // Student lists
  enrolledStudentIds: [
    "ROLL001",
    "ROLL002",
    "ROLL003"
  ],
  
  presentStudentIds: [
    "ROLL001",
    "ROLL003"  // ROLL002 marked absent
  ],
  
  // Optional metadata
  location: "A101",
  notes: "Session complete"
}
```

---

## 🔄 Data Flow & Integration

### Database Schema Overview

#### Collections Structure

**1. students**
```
Document ID: {uid} (Firebase Auth UID)
Fields:
  - uid: string
  - name: string
  - rollno: string (unique identifier for queries)
  - email: string
  - department: string
  - year: number
  - section: string
  - phoneNumber: string (optional)
  - profileImageUrl: string (optional)
  - enrolledSubjects: array<string>
  - createdAt: timestamp
```

**2. faculty**
```
Document ID: {uid}
Fields:
  - uid: string
  - name: string
  - facultyId: string (employee ID)
  - email: string
  - department: string
  - phoneNumber: string (optional)
  - profileImageUrl: string (optional)
  - assignedSubjects: array<string>
  - createdAt: timestamp
```

**3. attendance**
```
Document ID: auto-generated
Fields:
  - facultyId: string
  - subjectCode: string
  - subjectName: string
  - date: string (YYYY-MM-DD)
  - timestamp: Timestamp
  - branch: string
  - year: string
  - section: string
  - periodNumber: number
  - enrolledStudentIds: array<string>
  - presentStudentIds: array<string>
  - location: string (optional)
  - notes: string (optional)
```

**4. faculty_timetables**
```
Document ID: {facultyId}
Fields:
  - facultyId: string
  - monday: array<{period, subject, code, room, startTime, endTime, students}>
  - tuesday: array<{...}>
  - wednesday: array<{...}>
  - thursday: array<{...}>
  - friday: array<{...}>
  - saturday: array<{...}>
  - sunday: array<{...}>
```

**5. academic_records** (Optional)
```
Document ID: auto-generated
Fields:
  - studentId: string (uid)
  - yearOfStudy: number
  - status: string (active/inactive)
  - enrollmentDate: timestamp
```

**6. subjects**
```
Document ID: auto-generated
Fields:
  - code: string
  - name: string
  - department: string
  - credits: number
```

### Data Fetching Patterns

#### Pattern 1: Real-time Streams (for dashboards)
```dart
// Faculty timetable - real-time updates
Stream<DocumentSnapshot> getFacultyTimetableStream(String facultyId)
  └→ _db.collection('faculty_timetables').doc(facultyId).snapshots()
```

#### Pattern 2: One-time Queries (for reports)
```dart
// Attendance records - filtered queries
Future<List<DocumentSnapshot>> getAttendanceRecords(String facultyId)
  ├→ where: facultyId == value
  ├→ where: date == selectedDate
  ├→ where: subjectCode == selectedSubject
  └→ orderBy: timestamp DESC
```

#### Pattern 3: Conditional Array Queries (core to attendance)
```dart
// Find attendance for specific student
Future<List<DocumentSnapshot>> getStudentAttendance(String rollNo)
  ├→ where: enrolledStudentIds arrayContains rollNo
  ├→ Calculate presence from presentStudentIds
  └→ Compute attendance percentage
```

### Integration Points

#### 1. Firebase Core Initialization
```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

#### 2. Local Authentication Server (Development)
```
Purpose: Custom token generation
URL: http://localhost:9002
Flow:
  LoginService
    └→ HTTP POST credentials
      └→ Auth server validates
        └→ Issues JWT token
          └→ Client uses for Firebase sign-in
```

#### 3. Cloud Storage (Images)
- Student/Faculty profile images
- ID card generation exports
- Report PDF storage

#### 4. Notifications (Potential)
- Class start reminders
- Attendance confirmations
- Low attendance alerts
- Report ready notifications

---

## 🎨 UI/UX Architecture

### Student App Structure
```
SplashScreen
    ↓
LoginScreen (credential entry)
    ↓
RoleRouter (checks student role)
    ↓
StudentShell
├── StudentDashboardScreen (Home)
│   ├── Profile card
│   ├── Attendance percentage
│   ├── Quick stats
│   └── Subject overview
│
├── StudentIdScreen
│   ├── Profile image
│   ├── Student info
│   ├── Barcode widget
│   └── Export/Share button
│
├── AttendanceOverviewScreen
│   ├── Overall stats
│   ├── Daily tab
│   ├── Weekly tab
│   ├── Monthly tab
│   └── Subject breakdown
│
└── StudentProfileScreen
    ├── Contact information
    ├── Academic details
    ├── Enrolled subjects
    └── Settings
```

### Faculty App Structure
```
SplashScreen
    ↓
LoginScreen
    ↓
RoleRouter (checks faculty role)
    ↓
FacultyShell
├── FacultyDashboardScreen
│   ├── Welcome greeting
│   ├── Today's date
│   ├── Classes today widget
│   │   ├── Subject list
│   │   ├── Time slots
│   │   ├── Student count
│   │   └── Quick mark attendance
│   └── Department info
│
├── TimetableScreen
│   ├── Weekly view
│   ├── Subject details
│   ├── Room assignments
│   ├── Class duration
│   └── Enrolled count
│
└── AttendanceReportScreen
    ├── Filter controls
    │   ├── Date picker
    │   ├── Subject dropdown
    │   ├── Branch/Year/Section
    │   └── Period selector
    ├── Statistics pills
    ├── Filter toggles
    │   ├── All
    │   ├── Present
    │   └── Absent
    └── Student detail table
        └── Roll + attendance status
```

### Navigation Patterns
- **Bottom Navigation Bar**: Main navigation (Student: 4 tabs, Faculty: 3 tabs)
- **Custom Nav Items**: Styled navigation indicators
- **Nested Navigation**: Date/time selectors within tabs
- **Modal Navigation**: Pop-ups for scanning, filters, etc.

---

## ⚙️ Key Controllers & State Management

### Student Controllers

#### StudentDashboardController
```
Manages:
  - Student profile loading
  - Attendance calculation
  - Academic records fetch
  - Error handling

Methods:
  - loadStudentData()
  - _calculateAttendance()
  - _getDepartmentName()
```

#### AttendanceOverviewController
```
Manages:
  - Attendance data fetching
  - Date range filtering
  - Statistics calculation
  - View switching

Methods:
  - loadAttendanceData()
  - getFilteredAttendance()
  - calculateStats()
```

#### StudentIdController
```
Manages:
  - ID card generation
  - Barcode encoding
  - Image handling

Methods:
  - generateBarcode()
  - shareIdCard()
```

### Faculty Controllers

#### FacultyDashboardController
```
Manages:
  - Faculty profile loading
  - Today's classes loading
  - Timetable parsing
  - UI updates

Methods:
  - load()
  - _loadFacultyProfile()
  - _loadTodayClasses()
```

#### ScannerController
```
Manages:
  - Barcode scan processing
  - Student validation
  - Present list management
  - Duplicate prevention

Methods:
  - onStudentScanned()
  - toggleFlash()
  - reset()
```

#### AttendanceReportController
```
Manages:
  - Filter options loading
  - Report data aggregation
  - Statistics calculation
  - Export preparation

Methods:
  - initialize()
  - applyFilters()
  - generateReport()
  - exportToPDF()
  - exportToCSV()
```

---

## 🔍 Data Fetching Mechanisms

### Firestore Query Patterns

#### 1. Document Retrieval
```dart
// Get single document
Future<DocumentSnapshot> getDocument(String collection, String docId)
  └→ _db.collection(collection).doc(docId).get()
```

#### 2. Array Contains Queries
```dart
// Core to attendance system
getAttendanceForStudentRoll(String rollNo)
  └→ where('enrolledStudentIds', arrayContains: rollNo)
     └→ Critical: Finds all classes where student is enrolled
```

#### 3. Range Queries (Date filters)
```dart
getAttendanceInRange(String rollNo, DateTime startDate, DateTime endDate)
  ├→ where('date', isGreaterThanOrEqualTo: startStr)
  ├→ where('date', isLessThanOrEqualTo: endStr)
  └→ orderBy('date'), orderBy('periodNumber')
```

#### 4. Equality Queries (Specific filters)
```dart
getAttendanceByDate(String rollNo, String date)
  ├→ where('date', isEqualTo: date)
  └→ where('enrolledStudentIds', arrayContains: rollNo)
```

#### 5. Compound Queries (Multiple filters)
```dart
AttendanceReportController query
  ├→ where('facultyId', isEqualTo: facultyId)
  ├→ where('date', isEqualTo: date)
  ├→ where('subjectCode', isEqualTo: subject)
  ├→ where('branch', isEqualTo: branch)
  ├→ where('year', isEqualTo: year)
  ├→ where('section', isEqualTo: section)
  └→ where('periodNumber', isEqualTo: period)
```

### Performance Considerations

#### Indexing Requirements
Compound queries in Firestore require indexes:
```
Index 1: (facultyId, date, subjectCode)
Index 2: (enrolledStudentIds, timestamp)
Index 3: (date, enrolledStudentIds)
Index 4: (date, enrolledStudentIds, periodNumber)
```

#### Query Optimization
- **Limit results**: `limit(100)` in student attendance queries
- **Pagination**: For large datasets, use `startAfter()` for pagination
- **Caching**: Consider local cache with `SharedPreferences`
- **Aggregation**: Client-side calculation to avoid complex aggregation queries

#### Real-time vs. One-time Fetching
```
Real-time (Streams):
  - Faculty timetables
  - Live scanner updates
  - Dashboard updates

One-time (Futures):
  - Login verification
  - Report generation
  - Profile loading
```

---

## 🛠️ Important Configuration Files

### pubspec.yaml Dependencies
```yaml
firebase_core: ^3.8.1          # Firebase initialization
firebase_auth: ^5.3.4          # Authentication
cloud_firestore: ^5.5.1        # Database
mobile_scanner: ^5.2.3         # Barcode scanning
barcode_widget: ^2.0.4         # Barcode generation
pdf: ^3.10.6                   # PDF export
csv: ^6.0.0                    # CSV export
provider: ^6.1.0               # State management
intl: ^0.19.0                  # Date formatting
logger: ^2.0.0                 # Logging
share_plus: ^10.1.2            # Share functionality
shared_preferences: ^2.2.2     # Local storage
http: ^1.2.2                   # HTTP requests
path_provider: ^2.1.2          # File path access
```

### Firebase Configuration
```dart
// firebase_options.dart (generated)
- Platform-specific Firebase credentials
- API keys
- App IDs
- Project configuration
```

### Theme Configuration
```dart
// colors.dart, theme/
- Primary colors
- Accent colors
- Text styles
- Component themes
```

---

## 🚀 Deployment & Build Configuration

### Platform Support
```
Android:
  - Minimum SDK: Defined in android/app/build.gradle.kts
  - Firebase integration via google-services.json
  - Barcode scanner permissions

iOS:
  - iOS minimum version configuration
  - Firebase integration via GoogleService-Info.plist
  - Camera permissions in Info.plist

Web:
  - Responsive design
  - Index.html manifest

Linux/macOS/Windows:
  - Desktop platform support
```

### Build Process
```
Flutter build process:
  ├→ flutter pub get (dependency resolution)
  ├→ Generate platform-specific code
  ├→ Compile to native code
  └→ Create APK/IPA/Web bundle
```

---

## 📊 Statistics & Metrics

### Attendance Calculation Method

**Formula:**
```
Attendance % = (Number of Classes Attended / Total Classes Enrolled) × 100
```

**Implementation:**
```dart
// Key constraint: Only count enrolled classes
for (var doc in attendanceSnap.docs) {
  final enrolledList = data['enrolledStudentIds'];
  final presentList = data['presentStudentIds'];
  
  if (enrolledList.contains(rollNo)) {  // ← Critical check
    totalClasses++;
    if (presentList.contains(rollNo)) {
      presentCount++;
    }
  }
}
```

**Subject-wise Breakdown:**
```
Example:
  Data Structures: 95% (19/20 classes)
  Algorithms: 88% (18/20 classes)
  Database Systems: 92% (23/25 classes)
```

---

## 🔒 Security Best Practices Implemented

✅ **Firebase Authentication**: Secure credential handling  
✅ **Custom Tokens**: Backend-issued tokens for additional security  
✅ **Autofill Integration**: OS-level credential management  
✅ **Field Validation**: Input validation on forms  
✅ **Error Handling**: Graceful error messages without exposing internals  

### Recommendations for Production

1. **Firestore Security Rules**
   ```
   // Students can only see their own records
   match /students/{uid} {
     allow read: if request.auth.uid == uid;
   }
   
   // Faculty can only modify their own attendance
   match /attendance/{doc} {
     allow read: if request.auth.token.role == 'faculty' && request.auth.uid == resource.data.facultyId;
     allow write: if request.auth.token.role == 'faculty' && request.auth.uid == resource.data.facultyId;
   }
   ```

2. **Backend Validation**: All data modifications should be validated server-side

3. **Rate Limiting**: Implement to prevent abuse of scanning, queries

4. **Audit Logging**: Log all attendance modifications for compliance

---

## 📝 Usage Workflows Summary

### Student Workflow

```
1. Launch App → SplashScreen → LoadAuth
2. Login with roll number & password
3. Authenticated → StudentShell
4. Access:
   ✓ Dashboard: View attendance %, profile summary
   ✓ ID Card: Display barcode for attendance marking
   ✓ Attendance: View daily/weekly/monthly breakdown
   ✓ Profile: View/edit personal information
5. Logout to return to login
```

### Faculty Workflow

```
1. Launch App → SplashScreen → LoadAuth
2. Login with faculty ID & password
3. Authenticated → FacultyShell
4. Access:
   ✓ Dashboard: View today's classes, quick stats
   ✓ Timetable: View weekly schedule
   ✓ Scanner: Open barcode scanner for attendance
     - Scan student IDs
     - Validate enrollment
     - Confirm and submit
   ✓ Reports: Generate attendance reports with filters
     - Export to PDF/CSV
     - Analyze student attendance
5. Logout
```

---

## 🔄 Future Enhancement Opportunities

1. **Push Notifications**: Real-time alerts for low attendance
2. **SMS Integration**: Absence alerts to parents
3. **Mobile Biometrics**: Face recognition for attendance
4. **Offline Mode**: Work without internet, sync later
5. **Analytics Dashboard**: Department-wide analytics
6. **Mobile App Hardening**: Encryption, secure storage
7. **Multi-language Support**: Localization for different regions
8. **Accessibility**: WCAG compliance improvements
9. **Advanced Reports**: Predictive analytics, trend analysis
10. **Integration APIs**: REST APIs for third-party systems

---

## 📞 Support & Maintenance

### Development Setup
- Requires Flutter 3.10.4+ SDK
- Firebase project configuration
- Local auth server setup (for development)
- Android/iOS development tools

### Common Issues & Solutions

**Issue**: Firebase initialization fails
- **Solution**: Verify `firebase_options.dart` matches your Firebase project

**Issue**: Barcode scanning not working
- **Solution**: Check camera permissions in manifest files

**Issue**: Attendance not calculating correctly
- **Solution**: Verify `enrolledStudentIds` array is populated in attendance collection

**Issue**: Authentication fails
- **Solution**: Verify auth server is running (localhost:9002) and credentials exist

---

## 📚 Documentation References

- [Flutter Documentation](https://flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloud Firestore Guide](https://firebase.google.com/docs/firestore)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [mobile_scanner Package](https://pub.dev/packages/mobile_scanner)
- [Provider Pattern](https://pub.dev/packages/provider)

---

## 📄 Project Metadata

- **Project Name**: sbas_attendance
- **Version**: 1.0.0+1
- **Created Date**: January 2026
- **Last Updated**: January 16, 2026
- **Platform**: Flutter (iOS, Android, Web, Linux, macOS, Windows)
- **Architecture**: MVC with Service Layer
- **State Management**: ChangeNotifier + Provider Pattern
- **Backend**: Firebase (Auth + Firestore)
- **Build System**: Flutter build tools

---

**End of Report**

This comprehensive report provides detailed insights into the SBAS Attendance system, covering architecture, workflows, data structures, and implementation details. The system is well-suited for educational institutions looking to modernize their attendance management processes.
