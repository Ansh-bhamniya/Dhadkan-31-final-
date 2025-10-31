import 'package:dhadkan/Custom/custom_elevated_button.dart';
import 'package:dhadkan/features/auth/doctor_sign_up_screen.dart';
import 'package:dhadkan/features/auth/patient_sign_up_screen.dart';
import 'package:dhadkan/features/common/top_bar.dart';
import 'package:flutter/material.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TopBar(title: "Sign Up")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              Container(
                  child: const Text('You are a ...',
                      style: TextStyle(
                        fontSize: 20,
                      ))),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Patient Tile with Logo
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // White background tile
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                // Shadow effect
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/Images/patient.png',
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomElevatedButton(
                          height: 50, // Increased height for larger button
                          width: double.infinity, // Stretch to take up space
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PatientSignUpScreen(),
                              ),
                            );
                          },
                          text: 'Patient',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20), // Spacing between buttons
                  Expanded(
                    child: Column(
                      children: [
                        // Doctor Tile with Logo
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // White background tile
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                // Shadow effect
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/Images/doctor.png',
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomElevatedButton(
                          height: 50, // Increased height for larger button
                          width: double.infinity, // Stretch to take up space
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DoctorSignUpScreen(),
                              ),
                            );
                          },
                          text: 'Doctor',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
