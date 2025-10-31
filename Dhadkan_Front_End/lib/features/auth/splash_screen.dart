import 'dart:async';

import 'package:dhadkan/features/auth/landing_screen.dart';
import 'package:dhadkan/features/doctor/home/doctor_home.dart';
import 'package:dhadkan/features/patient/home/patient_home_screen.dart';
import 'package:dhadkan/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() async {
    String? token;

    try {
      token = await SecureStorageService.getData('authToken');
    } catch (e) {
      // If there's a decryption error, clear secure storage
      await SecureStorageService.deleteAll();
      token = null;  // Treat as no token
    }

    Timer(const Duration(seconds: 2), () {
      if (token != null) {
        String role = getRole(token);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
            role == "patient" ? const PatientHome() : const DoctorHome(),
          ),
              (Route<dynamic> route) => false,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/Images/logo.png'),
      ),
    );
  }
}
