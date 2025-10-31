import 'package:dhadkan/features/auth/landing_screen.dart';
import 'package:dhadkan/features/common/top_bar.dart';
import 'package:dhadkan/features/doctor/home/heading.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';

import '../../../utils/device/device_utility.dart';
import 'doctor_buttons.dart';
import '../../pending/pending_queue.dart';
import '../../pending/pending_patient.dart';
import '../../pending/pending_sync_service.dart';

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  int _pendingCount = 0;
  @override
  void initState() {
    super.initState();
    _validateTokenInBackground();
    _initPending();
  }

  Future<void> _initPending() async {
    await PendingSyncService.init();
    setState(() {
      _pendingCount = PendingQueue.length();
    });
    // Attempt a quick sync when opening the home page
    await PendingSyncService.sync();
    if (!mounted) return;
    setState(() {
      _pendingCount = PendingQueue.length();
    });
  }

  Future<void> _validateTokenInBackground() async {
    String? token = await SecureStorageService.getData('authToken');
    if (token != null) {
      bool isValid = await _validateToken(token);
      if (!isValid && mounted) {
        _showSessionExpiredDialog();
      }
    } else {
      // No token found, force logout
      _forceLogout();
    }
  }

  Future<bool> _validateToken(String token) async {
    try {
      final response = await MyHttpHelper.private_post('/patient/validate-token', {}, token);
      return response['status'] == 'valid';
    } catch (e) {
      //print("Error validating token: $e");
      // You can decide: consider invalid, or allow offline mode
      return false;
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Session Expired"),
        content: const Text("Your session has expired. Please log in again."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _forceLogout();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _forceLogout() async {
    await SecureStorageService.deleteData('authToken');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LandingScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MyDeviceUtils.getScreenWidth(context);
    double paddingWidth = screenWidth * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: const TopBar(title: "Welcome, Doctor"),
        actions: [
          // Pending requests button with badge
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PendingPatientScreen()),
              );
              setState(() {
                _pendingCount = PendingQueue.length();
              });
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.cloud_upload_outlined),
                if (_pendingCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          _pendingCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Pending requests',
          ),
          IconButton(
            onPressed: () {
              _forceLogout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingWidth),
        child: const SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 15),
              Heading(),
              SizedBox(height: 15),
              DoctorButtons(),
              SizedBox(height: 15),
              // DoctorHistogram(),
              // DoctorPie(),
            ],
          ),
        ),
      ),
    );
  }
}
