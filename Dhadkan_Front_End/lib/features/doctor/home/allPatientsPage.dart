import 'package:dhadkan/features/auth/landing_screen.dart';
import 'package:dhadkan/features/doctor/home/patient_drugdatascreen.dart';
import 'package:dhadkan/features/patient/home/patient_graph.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/constants/colors.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/features/common/top_bar.dart';

class AllPatientsPage extends StatefulWidget {
  const AllPatientsPage({super.key});

  @override
  _AllPatientsPageState createState() => _AllPatientsPageState();
}

class _AllPatientsPageState extends State<AllPatientsPage> {
  List<dynamic> data = [];
  List<dynamic> filteredData = []; // New: List to store filtered patients
  bool isLoading = true;
  String _token = "";
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController(); // New: Controller for search input

  @override
  void initState() {
    super.initState();
    _initialize();
    // New: Add listener for search input changes
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose(); // New: Clean up controller
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final token = await SecureStorageService.getData('authToken');
      if (token == null || token.isEmpty) {
        _redirectToLanding();
      } else {
        setState(() => _token = token);
        await _fetchPatients();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Initialization failed";
        isLoading = false;
      });
      // print("Error during initialization: $e");
    }
  }

  void _redirectToLanding() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
      );
    });
  }

  Future<void> _fetchPatients() async {
    try {
      setState(() => isLoading = true);
      final response = await MyHttpHelper.private_post(
          '/doctor/allpatient',
          {},
          _token
      );

      if (response['success'] == true || response['success'] == 'true') {
        setState(() {
          data = List<dynamic>.from(response['data'] ?? []);
          filteredData = data; // New: Initialize filteredData with all patients
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = response['message']?.toString() ?? "Failed to load patients";
        });
      }
    } catch (e) {
      setState(() => _errorMessage = "Network error occurred");
      // print("Error fetching patients: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // New: Function to filter patients based on search input
  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => filteredData = data);
      return;
    }

    setState(() {
      filteredData = data.where((item) {
        if (item is! Map<String, dynamic>) return false;
        final patient = item['patient'] as Map<String, dynamic>? ?? {};
        final name = patient['name']?.toString().toLowerCase() ?? '';
        final uhid = patient['uhid']?.toString().toLowerCase() ?? '';
        final mobile = patient['mobile']?.toString().toLowerCase() ?? '';
        return name.contains(query) || uhid.contains(query) || mobile.contains(query);
      }).toList();
    });
  }

  Widget _buildPatientCard(Map<String, dynamic> patientData) {
    final patient = patientData['patient'] as Map<String, dynamic>? ?? {};
    final graphData = patientData['graphData'];

    final name = (patient.containsKey('name') ? patient['name']?.toString() : null) ?? 'Name not available';
    final mobile = (patient.containsKey('mobile') ? patient['mobile']?.toString() : null) ?? 'Mobile not available';
    final patientId = (patient.containsKey('_id') ? patient['_id']?.toString() : null) ?? '_id not available';
    final uhid = (patient.containsKey('uhid') ? patient['uhid']?.toString() : null) ?? 'UHID not available';

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                    Text('UHID:$uhid', style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700])),
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _navigateToPatientDetail(mobile, name, patientId),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerRight,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'More Info',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          if (graphData != null && graphData is Map<String, dynamic> && graphData.isNotEmpty)
            PatientGraph(graphData: graphData)
          else
            const Text("No health data available",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _navigateToPatientDetail(String mobile, String name, String patientId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDrugDataScreen(
          patientMobile: mobile,
          patientName: name,
          patientId: patientId,
        ),
      ),
    );
    await _fetchPatients(); // Refresh data after returning
  }

  @override
  Widget build(BuildContext context) {
    final paddingWidth = MyDeviceUtils.getScreenWidth(context) * 0.05;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            ElevatedButton(
              onPressed: _fetchPatients,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (data.isEmpty) {
      return const Center(child: Text("No patients found"));
    }

    return Scaffold(
      appBar: AppBar(title: const TopBar(title: "All Patients")),
      body: RefreshIndicator(
        onRefresh: _fetchPatients,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingWidth),
          child: Column(
            children: [
              // Search bar with reduced font size and height
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14), // Reduced font size for input text
                  decoration: InputDecoration(
                    hintText: 'Search by Name, UHID or Mobile Number',
                    hintStyle: const TextStyle(fontSize: 14), // Reduced font size for hint text
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20), // Reduced vertical padding for height
                  ),
                ),
              ),
              // Total patients count just below the search bar
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Total patients: ${data.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MyColors.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in filteredData) // Updated: Use filteredData
                      if (item is Map<String, dynamic>)
                        _buildPatientCard(item)
                      else
                        (() {
                          // print('Skipping invalid patient data item: $item');
                          return const SizedBox.shrink();
                        })(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
