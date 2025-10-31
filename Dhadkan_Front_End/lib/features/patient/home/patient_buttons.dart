import 'package:dhadkan/features/patient/home/patient_button.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PatientButtons extends StatelessWidget {
  final String patientId;
  final String doctorId;
  const PatientButtons({
    super.key,
    required this.doctorId,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    void handleAddButtonPress() {
      Navigator.pushNamed(context, 'patient/add/');
    }

    void handleChatPress() {
      Navigator.pushNamed(
        context,
        'chat/',
        arguments: doctorId,
      );
    }

    void handleReportsPress() {
      Navigator.pushNamed(
        context,
        'reports/',
        arguments: patientId,
      );
    }

    var screenWidth = MyDeviceUtils.getScreenWidth(context);
    var width = screenWidth * 0.9;
    return Container(
      width: width,
      height: 50,
      decoration: BoxDecoration(
          // color: Colors.white,
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PatientButton(title: "Add Data", handleClick: handleAddButtonPress),
          const SizedBox(
            width: 20,
          ),
          PatientButton(title: "Notification",
          handleClick: handleChatPress,
          // handleChatButtonPress
          ),
          const SizedBox(
            width: 20,
          ),
          PatientButton(title: "Reports", handleClick: handleReportsPress,),
        ],
      ),
    );
  }
}
