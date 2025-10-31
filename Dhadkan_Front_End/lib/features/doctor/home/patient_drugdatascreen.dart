import 'package:dhadkan/features/doctor/doctor_buttonsindisplaydata.dart';
import 'package:dhadkan/features/patient/home/patient_graph.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/features/doctor/home/drug.dart/adddrug.dart';

// Function to fetch patient drug data using existing HTTP client
Future<List<PatientDrugRecord>> fetchPatientDrugData(
    String patientMobile, String token, {String? date}) async { // Added date parameter
  final Map<String, dynamic> body = {};
  if (date != null) {
    body['date'] = date;
  }
  final response = await MyHttpHelper.private_post(
      '/doctor/patient-drug-data/mobile/$patientMobile', body, token);

  // Safely handle potential null or non-list 'data'
  if (response['data'] is List) {
    List<PatientDrugRecord> records = List<PatientDrugRecord>.from(
        (response['data'] as List).map((item) => PatientDrugRecord.fromJson(item)));
    return records;
  } else {
    // Return an empty list if 'data' is not a list or is null
    return [];
  }
}


// Function to fetch patient details
Future<Map<String, dynamic>> fetchPatientDetails(
    String patientmobile, String token) async {
  try {
    final response = await MyHttpHelper.private_post(
        '/doctor/getinfo/$patientmobile', {}, token);

    if (response.containsKey('status') && response['status'] == 'success') {
      return response['data'];
    } else {
      throw Exception(response['message'] ?? 'Failed to fetch patient details');
    }
  } catch (e) {
    throw Exception('Error fetching patient details: $e');
  }
}

// Class to hold patient details
class PatientDetails {
  final String name;
  final String uhid;
  final String age;
  final String gender;
  final String mobile;
  final String disease;

  PatientDetails({
    required this.name,
    required this.uhid,
    required this.age,
    required this.gender,
    required this.mobile,
    required this.disease,
  });

  factory PatientDetails.fromJson(Map<String, dynamic> json) {
    return PatientDetails(
      name: json['name'] ?? 'N/A',
      uhid: json['uhid'] ?? 'N/A',
      age: json['age']?.toString() ?? 'N/A',
      gender: json['gender'] ?? 'N/A',
      mobile: json['mobile'] ?? 'N/A',
      disease: json['diagnosis'] == 'Other'
          ? json['customDisease'] ?? 'N/A'
          : json['diagnosis'] ?? 'N/A',
    );
  }
}

class PatientDrugDataScreen extends StatefulWidget {
  final String patientMobile;
  final String patientName;
  final String patientId;
  const PatientDrugDataScreen({
    super.key,
    required this.patientMobile,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<PatientDrugDataScreen> createState() => _PatientDrugDataScreenState();
}

class _PatientDrugDataScreenState extends State<PatientDrugDataScreen> {
  String _token = "";
  bool _isLoading = true;
  List<PatientDrugRecord> _allDrugRecords = []; // Stores all records for the graph
  List<PatientDrugRecord> _filteredDrugRecords = []; // Stores filtered records for display
  String _errorMessage = '';
  PatientDetails? _patientDetails;
  bool _loadingPatientDetails = true;
  String _patientDetailsError = '';
  DateTime? _selectedDate; // State variable for selected date

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    String? token = await SecureStorageService.getData('authToken');
    if (mounted) {
      setState(() {
        _token = token ?? '';
      });

      if (_token.isNotEmpty) {
        await Future.wait([
          _fetchAllAndFilterDrugData(), // Changed to new function
          _fetchPatientDetails(),
        ]);
      } else {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
          _loadingPatientDetails = false;
        });
      }
    }
  }

  Future<void> _fetchAllAndFilterDrugData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Fetch all records first (without date filter)
      final allRecords = await fetchPatientDrugData(
        widget.patientMobile,
        _token,
        date: null, // Ensure no date filter is applied for all records
      );

      // Now filter these records based on _selectedDate for display
      List<PatientDrugRecord> recordsForDisplay = allRecords;
      if (_selectedDate != null) {
        final selectedDateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        recordsForDisplay = allRecords.where((record) {
          if (record.createdAt == null) return false;
          final recordDate = DateTime.parse(record.createdAt!).toLocal(); // Convert to local time for comparison
          return DateFormat('yyyy-MM-dd').format(recordDate) == selectedDateFormatted;
        }).toList();
      }

      if (mounted) {
        setState(() {
          _allDrugRecords = allRecords; // Store all records for the graph
          _filteredDrugRecords = recordsForDisplay; // Store filtered records for display
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching drug data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPatientDetails() async {
    try {
      final detailsData =
      await fetchPatientDetails(widget.patientMobile, _token);
      if (mounted) {
        setState(() {
          _patientDetails = PatientDetails.fromJson(detailsData);
          _loadingPatientDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _patientDetailsError =
          'Error fetching patient details: ${e.toString()}';
          _loadingPatientDetails = false;
        });
      }
    }
  }

  Future<void> _requestDeleteRecord(String recordId) async {
    if (_token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Authentication error. Please log in again.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
              'Are you sure you want to delete this history entry? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting entry...')),
      );

      try {
        final response = await MyHttpHelper.private_delete(
          '/doctor/history/$recordId',
          _token,
        );

        if (!mounted) return;

        if (response['success'] == true ||
            response['success'] == 'true' ||
            response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('History entry deleted successfully!'),
                backgroundColor: Colors.green),
          );
          // Update both lists
          setState(() {
            _allDrugRecords.removeWhere((record) => record.id == recordId);
            _filteredDrugRecords.removeWhere((record) => record.id == recordId);
          });
        } else {
          final errorMessage =
              response['message'] ?? 'Failed to delete. Server error.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $errorMessage'),
                backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, dynamic> _generateGraphData() {
    // Use _allDrugRecords for the graph
    List<dynamic> sbpValues = [];
    List<dynamic> dbpValues = [];
    List<dynamic> hrValues = [];
    List<dynamic> weightValues = [];

    // Sort _allDrugRecords by createdAt to ensure graph data is chronological
    _allDrugRecords.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return DateTime.parse(a.createdAt!).compareTo(DateTime.parse(b.createdAt!));
    });

    for (var record in _allDrugRecords) {
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
      _fetchAllAndFilterDrugData(); // Refetch all data and then filter
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF03045E),
        title: Text(
          'Drug data for ${widget.patientName}',
          style: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _fetchAllAndFilterDrugData(); // Re-trigger data fetch
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    Map<String, dynamic> graphData =
    _allDrugRecords.isNotEmpty ? _generateGraphData() : _generateEmptyGraphData();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPatientDetailsCard(),
        PatientGraph(graphData: graphData),
        const SizedBox(height: 10),
        DoctorButtonsindisplaydata(
            patientMobile: widget.patientMobile, patientId: widget.patientId),
        const SizedBox(height: 16),
        // Date Filter Section
        _buildDateFilter(),
        const SizedBox(height: 16),
        if (_filteredDrugRecords.isEmpty) // Use _filteredDrugRecords here
          Center(
            child: Text(
              _selectedDate != null
                  ? 'No records found for ${_formatDateForDisplay(_selectedDate!)}.'
                  : 'No drug records available.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        if (_filteredDrugRecords.isNotEmpty) // Use _filteredDrugRecords here
          ...List.generate(_filteredDrugRecords.length, (index) {
            return _buildDrugRecordCard(_filteredDrugRecords[index]);
          }),
      ],
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
                _fetchAllAndFilterDrugData(); // Refetch all data and then filter
              },
              tooltip: 'Clear Date Filter',
            ),
        ],
      ),
    );
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Widget _buildDrugRecordCard(PatientDrugRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecordHeader(record),
                const SizedBox(height: 10),
                _buildPatientInfo(record),
                _buildDiagnosisAndAbility(record),
                _buildMedicinesTitle(),
                if (record.medicines != null && record.medicines!.isNotEmpty)
                  _buildMedicinesList(record.medicines!),
              ],
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                    tooltip: 'Edit this entry',
                    onPressed: () {
                      if (record.id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddDrugPage(
                              patientMobile: widget.patientMobile,
                              record: record,
                              recordId: record.id!, // Pass the _id
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: Record ID is missing.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFFF5A5A)),
                    tooltip: 'Delete this entry',
                    onPressed: () {
                      if (record.id != null) {
                        _requestDeleteRecord(record.id!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: Record ID is missing.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordHeader(PatientDrugRecord record) {
    String dateStr = _formatDate(record.createdAt);
    String timeStr = _formatTime(record.createdAt);

    return Center(
      child: Column(
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF03045E),
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(PatientDrugRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Status', record.status ?? 'Better'),
            _buildInfoRow('Weight', record.weight?.toString() ?? ''),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoRow('Can walk for 5 min', record.canWalk ?? 'YES'),
            _buildInfoRow('SBP', record.sbp?.toString() ?? ''),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Can climb stairs', record.canClimb ?? 'YES'),
            _buildInfoRow('DBP', record.dbp?.toString() ?? ''),
          ],
        ),
        // Add HR row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 1), // Empty space to balance layout
            _buildInfoRow('HR', record.hr?.toString() ?? ''),
          ],
        ),
      ],
    );
  }

  Widget _buildDiagnosisAndAbility(PatientDrugRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
            'Diagnosis',
            (record.diagnosis == 'Other'
                ? record.otherDiagnosis
                : record.diagnosis) ??
                'N/A'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesTitle() {
    return const Center(
      child: Text(
        'Medicines',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF03045E),
        ),
      ),
    );
  }

  Widget _buildMedicinesList(List<Medicine> medicines) {
    // Group medicines by medClass
    final Map<String, List<Medicine>> groupedMedicines = {
      'A': [],
      'B': [],
      'C': [],
      'D': [],
    };

    // Categorize medicines by medClass
    for (var medicine in medicines) {
      final medClass = medicine.medClass ?? '';
      if (groupedMedicines.containsKey(medClass)) {
        groupedMedicines[medClass]!.add(medicine);
      }
    }

    // Sort medicines within each class by name
    groupedMedicines.forEach((key, value) {
      value.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    });

    // Build UI for each class
    List<Widget> classSections = [];
    groupedMedicines.forEach((medClass, meds) {
      if (meds.isNotEmpty) {
        classSections.add(
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
            child: Text(
              'Medicine $medClass :',
              style: const TextStyle(
                fontSize: 14, // Match font size of status and other fields
                fontWeight: FontWeight.bold,
                color: Colors.black, // Use black color
              ),
            ),
          ),
        );
        classSections.addAll(
          meds.asMap().entries.map((entry) {
            final medicine = entry.value;
            return _buildCollapsibleMedicineItem(medicine, medClass);
          }).toList(),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: classSections,
    );
  }

  Widget _buildCollapsibleMedicineItem(Medicine medicine, String label) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          medicine.name ?? 'N/A',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding:
        const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(
                          text: 'Format: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: medicine.format ?? 'N/A'),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(
                          text: 'Dosage: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '${medicine.dosage ?? 'N/A'} mg'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    const TextSpan(
                      text: 'Frequency: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: medicine.frequency ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    const TextSpan(
                      text: 'Timing: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: medicine.medicineTiming ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    const TextSpan(
                      text: 'Generic: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: medicine.generic ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    const TextSpan(
                      text: 'Company name: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: medicine.companyName ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsCard() {
    if (_loadingPatientDetails) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20.0),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_patientDetailsError.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Could not load patient details",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_patientDetailsError,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loadingPatientDetails = true;
                  _patientDetailsError = '';
                });
                _fetchPatientDetails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/Images/patient2.png'),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientDetailRow('Name', _patientDetails?.name ?? 'N/A'),
                  _buildPatientDetailRow('Age', _patientDetails?.age ?? 'N/A'),
                  _buildPatientDetailRow('Gender', _patientDetails?.gender ?? 'N/A'),
                  _buildPatientDetailRow('Phone', _patientDetails?.mobile ?? 'N/A'),
                  _buildPatientDetailRow('Disease', _patientDetails?.disease ?? 'N/A'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final istDate = date.add(const Duration(hours: 5, minutes: 30));
      final day = istDate.day;
      final month = DateFormat('MMM').format(istDate);
      return '$day${_getDaySuffix(day)} $month';
    } catch (e) {
      return dateStr;
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final istDate = date.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('h:mm a').format(istDate).toLowerCase();
    } catch (e) {
      return dateStr;
    }
  }
}

class PatientDrugRecord {
  final String? id;
  final String? name;
  final int? age;
  final int? weight;
  final int? sbp;
  final int? dbp;
  final int? hr; // HR field
  final String? diagnosis;
  final String? otherDiagnosis;
  final String? mobile;
  final String? status;
  final String? fillername;
  final String? canWalk;
  final String? canClimb;
  final List<Medicine>? medicines;
  final String? createdBy;
  final String? createdAt;

  PatientDrugRecord({
    this.id,
    this.name,
    this.age,
    this.weight,
    this.sbp,
    this.dbp,
    this.hr, // Added HR parameter
    this.diagnosis,
    this.otherDiagnosis,
    this.mobile,
    this.status,
    this.fillername,
    this.canWalk,
    this.canClimb,
    this.medicines,
    this.createdBy,
    this.createdAt,
  });

  factory PatientDrugRecord.fromJson(Map<String, dynamic> json) {
    return PatientDrugRecord(
      id: json['_id'],
      name: json['name'],
      age: json['age'] is String ? int.tryParse(json['age']) : json['age'],
      weight:
      json['weight'] is String ? int.tryParse(json['weight']) : json['weight'],
      sbp: json['sbp'] is String ? int.tryParse(json['sbp']) : json['sbp'],
      dbp: json['dbp'] is String ? int.tryParse(json['dbp']) : json['dbp'],
      hr: json['hr'] is String ? int.tryParse(json['hr']) : json['hr'], // Parse HR
      diagnosis: json['diagnosis'],
      otherDiagnosis: json['otherDiagnosis'],
      mobile: json['mobile'],
      status: json['status'],
      fillername: json['fillername'],
      canWalk: json['can_walk'],
      canClimb: json['can_climb'],
      medicines: (json['medicines'] as List<dynamic>?)
          ?.map((e) => Medicine.fromJson(e))
          .toList(),
      createdBy: json['created_by'],
      createdAt: json['created_at'],
    );
  }
}

class Medicine {
  final String? name;
  final String? format;
  final String? dosage;
  final String? frequency;
  final String? companyName;
  final String? generic;
  final String? medClass; // Re-added medClass to match backend 'class' field
  final String? medicineTiming;

  Medicine({
    this.name,
    this.format,
    this.dosage,
    this.frequency,
    this.companyName,
    this.generic,
    this.medClass, // Added medClass
    this.medicineTiming,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      format: json['format'],
      dosage: json['dosage'],
      frequency: json['frequency'] == 'Other'
          ? json['customFrequency'] ?? json['frequency']
          : json['frequency'],
      companyName: json['company_name'],
      generic: json['generic'],
      medClass: json['class'], // Map backend 'class' to medClass
      medicineTiming: json['medicineTiming'],
    );
  }
}
