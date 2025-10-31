import 'package:dhadkan/features/common/graph.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:flutter/material.dart';

class PatientGraph extends StatelessWidget {
  final Map<String, dynamic> graphData;

  const PatientGraph({super.key, required this.graphData});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MyDeviceUtils.getScreenWidth(context);
    double width = screenWidth * 0.9;

    // Convert all data types including hr
    List<double> diastolic = convertType(graphData['dbp']);
    List<double> systolic = convertType(graphData['sbp']);
    List<double> weight = convertType(graphData['weight']);
    List<double> hr = convertType(graphData['hr']); // Add hr data conversion

    // Generate x-values based on the maximum length of all data arrays
    int maxLength = 0;
    if (diastolic.isNotEmpty || systolic.isNotEmpty || weight.isNotEmpty || hr.isNotEmpty) {
      maxLength = [diastolic.length, systolic.length, weight.length, hr.length]
          .reduce((a, b) => a > b ? a : b);
    }

    List<double> xValues = [];
    for (int i = 0; i < maxLength; i++) {
      xValues.add(i.toDouble());
    }

    // Pad all arrays to match maxLength
    while (diastolic.length < maxLength) {
      diastolic.add(0.0);
    }
    while (systolic.length < maxLength) {
      systolic.add(0.0);
    }
    while (weight.length < maxLength) {
      weight.add(0.0);
    }
    while (hr.length < maxLength) {
      hr.add(0.0); // Pad hr array
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10)
      ),
      child: Graph(
        times: xValues,
        diastolic: diastolic,
        systolic: systolic,
        weight: weight,
        hr: hr, // Pass hr data to Graph widget
        width: width - 36,
      ),
    );
  }

  static List<double> convertType(List<dynamic>? arr) {
    if (arr == null || arr.isEmpty) return [];

    return arr.map((e) {
      if (e is num) {
        return e.toDouble();
      } else if (e is String) {
        return double.tryParse(e) ?? 0.0;
      }
      return 0.0;
    }).toList();
  }
}