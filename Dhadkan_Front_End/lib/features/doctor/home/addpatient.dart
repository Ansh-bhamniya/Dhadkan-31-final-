import 'package:dhadkan/features/common/top_bar.dart';
import 'package:dhadkan/features/doctor/home/patient_adder.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
class AddPatient extends StatefulWidget {
  const AddPatient({super.key});
  @override

  State<AddPatient> createState() => _AddPatientState();
}
class _AddPatientState extends State<AddPatient> {
  @override
  Widget build(BuildContext context) {
    var screenWidth = MyDeviceUtils.getScreenWidth(context);
    var paddingWidth = screenWidth * 0.05;
    return Scaffold(
      appBar: AppBar(
        title: const TopBar(title: "Add Patient"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingWidth),
        child: const SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 15),
              Patientadder(),
            ],
          ),
        ),
      ),
    );
  }
}
