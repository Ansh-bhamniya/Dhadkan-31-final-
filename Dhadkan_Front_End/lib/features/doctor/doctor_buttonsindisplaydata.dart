import 'package:dhadkan/features/doctor/home/doctor_button.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:flutter/material.dart';

class DoctorButtonsindisplaydata extends StatelessWidget {
  final String patientMobile;
  final String patientId;

  const DoctorButtonsindisplaydata({
    super.key,
    required this.patientMobile,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    void handleAdddrugPatientPress() {
      Navigator.pushNamed(
        context,
        'doctor/adddrugpatient/',
        arguments: patientMobile,
      );
    }

    void handleChatPress() {
      Navigator.pushNamed(
        context,
        'chat/',
        arguments: patientId,
      );
    }

    void handleReportsPress() {
      Navigator.pushNamed(
        context,
        'reports/',
        arguments: patientId,
      );
    }

    final screenWidth = MyDeviceUtils.getScreenWidth(context);
    final width = screenWidth * 0.9;

    return Container(
      width: width,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Doctorbutton(
            title: "Add Data",
            handleClick: handleAdddrugPatientPress,
          ),
          const SizedBox(width: 25),
          Doctorbutton(
            title: "Reports",
              handleClick: handleReportsPress,
          ),
          const SizedBox(width: 25),
          Doctorbutton(
            title: "Notify",
            handleClick: handleChatPress,
          ),
        ],
      ),
    );
  }
}