import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:dhadkan/features/auth/landing_screen.dart';
import 'package:dhadkan/features/common/top_bar.dart';
import 'package:dhadkan/features/patient/home/history.dart';
import 'package:dhadkan/features/patient/home/patient_buttons.dart';
import 'package:dhadkan/features/patient/home/patient_graph.dart';

// For http.delete


// Exporting models so history.dart can import them from here if needed,
// or ensure history.dart has its own correct model definitions.
// The provided history.dart already imports from '.../patient_home_screen.dart'
// so these models should be accessible.
export 'package:dhadkan/features/patient/home/patient_home_screen.dart' show PatientDrugRecord, Medicine;


//-------------------- Display Widget --------------------
class Display extends StatelessWidget {
  final dynamic data;
  const Display({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data?['name'] ?? 'N/A';
    final uhid = data?['uhid'] ?? 'N/A';
    final mobile = data?['mobile'] ?? 'N/A';
    final doctorMobile = data?['doctorMobile'] ?? 'N/A';
    // Assuming 'diagnosis' might not always be present in patientDetails for Display widget
    final diagnosisDisplay = data?['diagnosis']?.toString() ?? 'N/A';


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [
          Text("Name: ", style: MyTextTheme.textTheme.headlineSmall),
          Text(name, style: MyTextTheme.textTheme.bodyMedium),
        ]),
        Row(children: [
          Text("UHID: ", style: MyTextTheme.textTheme.headlineSmall),
          Text(uhid, style: MyTextTheme.textTheme.bodyMedium),
        ]),
        Row(children: [
          Text("Phone: ", style: MyTextTheme.textTheme.headlineSmall),
          Text(mobile, style: MyTextTheme.textTheme.bodyMedium),
        ]),
        Row(children: [
          Text("Doctor Mobile: ", style: MyTextTheme.textTheme.headlineSmall),
          Text(doctorMobile, style: MyTextTheme.textTheme.bodyMedium),
        ]),
        // Display diagnosis if available in the data passed to Display
        if (data?['diagnosis'] != null)
          Row(children: [
            Text("Disease: ", style: MyTextTheme.textTheme.headlineSmall),
            Text(diagnosisDisplay, style: MyTextTheme.textTheme.bodyMedium),
          ]),
      ],
    );
  }
}

//-------------------- Heading Widget --------------------
class Heading extends StatefulWidget {
  const Heading({super.key});

  @override
  _HeadingState createState() => _HeadingState();
}

class _HeadingState extends State<Heading> {
  String _token = "";
  Map<String, dynamic> patientDetails = {
    "name": "Loading...",
    "mobile": " ",
    "age": " ",
    "uhid": " ",
    "gender": " ",
    "doctorMobile": " ",
    "diagnosis": " ", // This might be specific to a record, not general patient details
    "id": " ",
    "doctorId": " ",
  };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  _initialize() async {
    String? token = await SecureStorageService.getData('authToken');
    if (!mounted) return;
    setState(() {
      _token = token ?? '';
    });

    if (_token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication error. Please login again.")));
      // Optionally navigate to login screen
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LandingScreen()));
      return;
    }

    try {
      // Assuming MyHttpHelper is configured with the base URL
      Map<String, dynamic> response = await MyHttpHelper.private_post(
          '/auth/get-details', {}, _token); // Endpoint for general patient details

      if (!mounted) return;

      if ((response['status'] == 'success' || response['success'] == true || response['success'] == 'true') && response['data'] != null) {
        //print("Patient Details fetched: ${response['data']}");
        setState(() {
          patientDetails = {
            "name": response['data']['name'] ?? "N/A",
            "mobile": response['data']['mobile'] ?? "N/A",
            "age": response['data']['age']?.toString() ?? "N/A",
            "uhid": response['data']['uhid'] ?? "N/A",
            "gender": response['data']['gender'] ?? "N/A",
            "doctorMobile": response['data']['doctor']?['mobile'] ?? response['data']['doctorMobile'] ?? "N/A", // Handle nested doctor object if applicable
            // "diagnosis" is usually part of a specific record, not general patient details.
            // If it is, ensure your /auth/get-details returns it.
            "diagnosis": response['data']['diagnosis'] ?? "N/A", // Or remove if not applicable here
            "id": response['data']['_id'] ?? response['data']['id'] ?? "N/A", // Prefer _id if from MongoDB
            "doctorId": response['data']['doctor']?['_id'] ?? response['data']['doctorId'] ?? "N/A",
          };
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load patient details: ${response['message'] ?? response['error'] ?? 'Unknown error'}")));
      }
    } catch (e) {
      if (!mounted) return;
      //print("Error loading patient details in Heading: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error loading patient data.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            )
          ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(45), // For circle
                image: const DecorationImage(
                  image: AssetImage('assets/Images/patient2.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/Images/patient2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.person, size: 60, color: Colors.grey.shade700);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Display(data: patientDetails),
            ),
          ],
        ),
      ),
    );
  }
}

//-------------------- Data Model Classes --------------------
// These models are defined here. Ensure history.dart uses these if it imports from this file.
class PatientDrugRecord {
  final String? id; // Corresponds to _id from MongoDB
  // final String? name; // Name of patient, usually in Heading, not repeated per record
  // final int? age; // Age of patient, usually in Heading
  final int? weight;
  final int? sbp;
  final int? dbp;
  final int? hr;
  final String? diagnosis;
  final String? otherDiagnosis;
  final String? mobile; // Patient's mobile, might be redundant if fetched once
  final String? status;
  // final String? fillername; // User who filled the data, if different from patient
  final String? canWalk;
  final String? canClimb;
  final List<Medicine>? medicines;
  final String? createdBy; // ID of user who created record
  final String? createdAt; // ISO date string

  PatientDrugRecord({ // Removed name, age, fillername from constructor if not in record itself
    this.id,
    this.weight,
    this.sbp,
    this.dbp,
    this.hr,
    this.diagnosis,
    this.otherDiagnosis,
    this.mobile,
    this.status,
    this.canWalk,
    this.canClimb,
    this.medicines,
    this.createdBy,
    this.createdAt,
  });

  factory PatientDrugRecord.fromJson(Map<String, dynamic> json) {
    return PatientDrugRecord(
      id: json['_id'], // Map _id to id
      // name: json['patient']?['name'], // If patient details are nested
      // age: json['patient']?['age'],
      weight: json['weight'] is String ? int.tryParse(json['weight']) : json['weight'],
      sbp: json['sbp'] is String ? int.tryParse(json['sbp']) : json['sbp'],
      dbp: json['dbp'] is String ? int.tryParse(json['dbp']) : json['dbp'],
      hr: json['hr'] is String ? int.tryParse(json['hr']) : json['hr'],
      diagnosis: json['diagnosis'],
      otherDiagnosis: json['otherDiagnosis'],
      mobile: json['mobile'], // This is mobile of patient for this record
      status: json['status'],
      // fillername: json['created_by_user']?['name'], // If created_by is populated with user object
      canWalk: json['can_walk'],
      canClimb: json['can_climb'],
      medicines: (json['medicines'] as List<dynamic>?)
          ?.map((e) => Medicine.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdBy: json['created_by'] is Map ? json['created_by']['_id'] : json['created_by'], // Handle populated or just ID
      createdAt: json['created_at'],
    );
  }
}

// In patient_home_screen.dart
class Medicine {
  final String? name;
  final String? format;
  final String? dosage;
  final String? frequency;
  final String? customFrequency;
  final String? companyName;
  final String? medClass; // Add class field
  final String? medicineTiming; // Add for line 348
  final String? generic; // Add for line 361

  Medicine({
    this.name,
    this.format,
    this.dosage,
    this.frequency,
    this.customFrequency,
    this.companyName,
    this.medClass, // Include in constructor
    this.medicineTiming, // Include in constructor
    this.generic, // Include in constructor
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      format: json['format'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      customFrequency: json['customFrequency'],
      companyName: json['company_name'],
      medClass: json['class'], // Map backend 'class' to medClass
      medicineTiming: json['medicineTiming'],
      generic: json['generic'],
    );
  }
}

//-------------------- PatientHome Screen --------------------
class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  _PatientHomeState createState() => _PatientHomeState();
}

// Moved _logout to be a static method or a top-level function if preferred
Future<void> _logout(BuildContext context) async {
  await SecureStorageService.deleteData('authToken');
  // Ensure context is still valid if operations are async before this
  if (!Navigator.of(context).mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LandingScreen()),
        (Route<dynamic> route) => false,
  );
}

class _PatientHomeState extends State<PatientHome> {
  String _token = "";
  Timer? _timer;
  String patientId = ""; // Logged-in user's ID (if patient) or target patient's ID
  String doctorId = "";
  List<PatientDrugRecord> _allHistoryRecords = []; // Stores all records for the graph
  List<PatientDrugRecord> _filteredHistoryRecords = []; // Stores filtered records for display
  bool _isLoadingHistory = true; // For history loading state
  Map<String, dynamic> graphData = {
    'sbp': [],
    'dbp': [],
    'hr': [],
    'weight': []
  };
  DateTime? _selectedDate; // New: State variable for selected date filter

  @override
  void initState() {
    super.initState();
    _initializeAndSetupTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAndSetupTimer() async {
    await _initializeToken();
    if (_token.isNotEmpty) {
      await _fetchPatientDetails(); // Fetches patientId and doctorId
      await _fetchData(); // Initial data fetch
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          _fetchData(isPeriodic: true); // Indicate periodic fetch
        } else {
          timer.cancel(); // Important to cancel if widget is disposed
        }
      });
    } else {
      // Token is empty, navigation is handled in _initializeToken
    }
  }

  Future<void> _initializeToken() async {
    String? token = await SecureStorageService.getData('authToken');
    if (!mounted) return;
    setState(() {
      _token = token ?? '';
    });

    if (_token.isEmpty) {
      _forceLogout("Authentication error. Please login again.");
      return;
    }

    bool isValid = await _validateToken(_token);
    if (!isValid) {
      _forceLogout("Session expired. Please login again.");
    }
  }
  Future<bool> _validateToken(String token) async {
    try {
      final response = await MyHttpHelper.private_post(
          '/patient/validate-token',
          {}, // No body needed
          token
      );

      if (response['status'] == 'valid') {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      //print("Token validation failed: $e");
      return false; // Treat errors as invalid token
    }
  }

  void _forceLogout(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    _logout(context);
  }


  Future<void> _fetchPatientDetails() async {
    if (_token.isEmpty) return;
    try {
      Map<String, dynamic> response = await MyHttpHelper.private_post(
          '/auth/get-details', {}, _token);
      if (!mounted) return;
      if ((response['status'] == 'success' || response['success'] == true || response['success'] == 'true') && response['data'] != null) {
        setState(() {
          // Assuming 'id' from /auth/get-details is the logged-in user's ID
          patientId = response['data']['_id'] ?? response['data']['id'] ?? '';
          // Assuming doctorId is part of patient's details or linked doctor's ID
          doctorId = response['data']['doctor']?['_id'] ?? response['data']['doctorId'] ?? '';
        });
      } else {
        //print("Failed to fetch patient details: ${response['message']}");
      }
    } catch (e) {
      //print('Error fetching patient details: $e');
    }
  }

  Future<void> _fetchData({bool isPeriodic = false}) async {
    if (_token.isEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingScreen()),
        );
      }
      return;
    }
    if (!mounted) return;

    if (!isPeriodic) { // Only set loading indicator for manual refresh/initial load
      setState(() { _isLoadingHistory = true; });
    }

    try {
      // Fetch all records without a date filter for the graph
      Map<String, dynamic> allRecordsResponse = await MyHttpHelper.private_post(
          '/patient/get-daily-data', {}, _token);

      if (!mounted) return;

      if ((allRecordsResponse['success'] == 'true' || allRecordsResponse['success'] == true) && allRecordsResponse['data'] != null) {
        List<dynamic> allPatientDrugData = allRecordsResponse['data'] ?? [];
        List<PatientDrugRecord> allRecords = allPatientDrugData
            .map((item) => PatientDrugRecord.fromJson(item as Map<String, dynamic>))
            .toList();

        // Filter records for display based on _selectedDate
        List<PatientDrugRecord> filteredRecords = allRecords;
        if (_selectedDate != null) {
          final selectedDateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate!);
          filteredRecords = allRecords.where((record) {
            if (record.createdAt == null) return false;
            final recordDate = DateTime.parse(record.createdAt!).toLocal();
            return DateFormat('yyyy-MM-dd').format(recordDate) == selectedDateFormatted;
          }).toList();
        }

        setState(() {
          _allHistoryRecords = allRecords; // Store all records
          _filteredHistoryRecords = filteredRecords; // Store filtered records for display
          graphData = _generateGraphDataFromRecords(_allHistoryRecords); // Graph uses all records
          _isLoadingHistory = false;
        });
      } else {
        setState(() { _isLoadingHistory = false; });
        //print("Failed to fetch daily data: ${allRecordsResponse['message']}");
      }
    } catch (e) {
      if (!mounted) return;
      //print('Error fetching daily data: $e');
      setState(() { _isLoadingHistory = false; });
    }
  }

  // Method to handle the delete request for a history record
  Future<void> _requestDeleteRecord(String recordId) async {
    if (_token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please log in again.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this history entry? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // User cancelled
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // User confirmed
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      // Show a temporary "Deleting..." SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting entry...')),
      );

      try {
        final response = await MyHttpHelper.private_delete(
          '/patient/history/$recordId', // Endpoint for deleting history record
          _token,
        );

        if (!mounted) return;

        if (response['success'] == true || response['success'] == 'true' || response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('History entry deleted successfully!'), backgroundColor: Colors.green),
          );
          // Update UI by removing the deleted item from the local state
          setState(() {
            _allHistoryRecords.removeWhere((record) => record.id == recordId);
            _filteredHistoryRecords.removeWhere((record) => record.id == recordId);
            graphData = _generateGraphDataFromRecords(_allHistoryRecords); // Re-generate graph data from all records
          });
        } else {
          final errorMessage = response['message'] ?? 'Failed to delete. Server error.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $errorMessage'), backgroundColor: Colors.red),
          );
          //print('Failed to delete history entry. Response: $response');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}'), backgroundColor: Colors.red),
        );
        //print('Error deleting history entry via PatientHomeScreen: $e');
      }
    }
  }


  Map<String, dynamic> _generateGraphDataFromRecords(List<PatientDrugRecord> records) {
    List<dynamic> sbpValues = [];
    List<dynamic> dbpValues = [];
    List<dynamic> hrValues = [];
    List<dynamic> weightValues = [];

    // Sort records by createdAt to ensure chronological order for the graph
    records.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return DateTime.parse(a.createdAt!).compareTo(DateTime.parse(b.createdAt!));
    });

    for (var record in records) {
      sbpValues.add(record.sbp ?? 0);
      dbpValues.add(record.dbp ?? 0);
      hrValues.add(record.hr ?? 0);
      weightValues.add(record.weight ?? 0);
    }

    return {
      'sbp': sbpValues,
      'dbp': dbpValues,
      'hr': hrValues,
      'weight': weightValues,
    };
  }

  Map<String, dynamic> _generateEmptyGraphData() {
    return {
      'sbp': [],
      'dbp': [],
      'hr': [],
      'weight': [],
    };
  }

  // New: Function to open date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData(); // Refetch all data and then filter
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal(); // Use toLocal() for device timezone
      final day = date.day;
      final month = DateFormat('MMM').format(date); // Month abbreviation
      return '$day${_getDaySuffix(day)} $month';
    } catch (e) {
      return dateStr; // Fallback
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal(); // Use toLocal()
      return DateFormat('h:mm a').format(date).toLowerCase(); // e.g., 5:30 pm
    } catch (e) {
      return dateStr; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> displayGraphData = (_allHistoryRecords.isNotEmpty)
        ? graphData
        : _generateEmptyGraphData();

    return Scaffold(
      appBar: AppBar(
        title: const TopBar(title: "Patient Home"), // Assuming TopBar is correctly implemented
        actions: [
          IconButton(
            onPressed: () {
              _logout(context); // Call the logout function
            },
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: RefreshIndicator( // Added RefreshIndicator for pull-to-refresh
        onRefresh: _fetchData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Ensures scrollability for RefreshIndicator
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Heading(),
                PatientGraph(graphData: displayGraphData),
                const SizedBox(height: 16),
                PatientButtons(patientId: patientId, doctorId: doctorId),
                const SizedBox(height: 22),
                // New: Date Filter Section
                _buildDateFilter(),
                const SizedBox(height: 16),
                _isLoadingHistory
                    ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CupertinoActivityIndicator(radius: 15)))
                    : History(
                  history: _filteredHistoryRecords, // Pass filtered records to History
                  formatDate: _formatDate,
                  formatTime: _formatTime,
                  onDeleteRecord: _requestDeleteRecord, // Pass the delete handler
                ),
                const SizedBox(height: 24)
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New: Widget to build the date filter section
  Widget _buildDateFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _selectedDate == null
                  ? 'Filter by Date'
                  : 'Selected Date: ${_formatDateForDisplay(_selectedDate!)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF03045E),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF03045E)),
            onPressed: () => _selectDate(context),
            tooltip: 'Select Date',
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
                _fetchData(); // Refetch data to clear filter
              },
              tooltip: 'Clear Date Filter',
            ),
        ],
      ),
    );
  }
}
