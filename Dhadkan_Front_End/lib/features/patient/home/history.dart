import 'package:flutter/material.dart';
import 'package:dhadkan/features/patient/home/patient_home_screen.dart';
import 'package:dhadkan/features/patient/addData/adddatascreen.dart';

class History extends StatelessWidget {
  final List<PatientDrugRecord> history;
  final String Function(String?) formatDate;
  final String Function(String?) formatTime;
  final Future<void> Function(String recordId) onDeleteRecord;
  // final String patientMobile;
  // final String patientName;
  // final String patientId;

  const History({
    super.key,
    required this.history,
    required this.formatDate,
    required this.formatTime,
    required this.onDeleteRecord,
    // required this.patientMobile,
    // required this.patientName,
    // required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'No history records found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...history.map((record) => _buildHistoryCard(record, context)),
      ],
    );
  }

  Widget _buildHistoryCard(PatientDrugRecord record, BuildContext context) {
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
                if (record.medicines != null && record.medicines!.isNotEmpty)
                  _buildMedicinesSection(record.medicines!, context),
              ],
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                    onPressed: () {
                      if (record.id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddData(
                              record: record,
                              recordId: record.id!,
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
                    onPressed: () {
                      if (record.id != null) {
                        onDeleteRecord(record.id!);
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
    String dateStr = formatDate(record.createdAt);
    String timeStr = formatTime(record.createdAt);

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
                color: Colors.grey),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 1),
            _buildInfoRow('HR', record.hr?.toString() ?? ''),
          ],
        ),
        _buildInfoRow(
            'Diagnosis',
            (record.diagnosis == 'Other' ? record.otherDiagnosis : record.diagnosis) ?? 'N/A'),
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

  Widget _buildMedicinesSection(List<Medicine> medicines, BuildContext context) {
    // Group medicines by medClass
    final Map<String, List<Medicine>> groupedMedicines = {
      'A': [],
      'B': [],
      'C': [],
      'D': [],
      'Other': [], // Add fallback category
    };

    // Categorize medicines by medClass
    for (var medicine in medicines) {
      final medClass = medicine.medClass ?? 'Other'; // Default to 'Other' if null
      groupedMedicines[medClass] ??= []; // Initialize list if key doesn't exist
      groupedMedicines[medClass]!.add(medicine);
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
            padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
            child: Text(
              'Medicine $medClass :',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        );
        classSections.addAll(
          meds.asMap().entries.map((entry) {
            final medicine = entry.value;
            return _buildCollapsibleMedicineItem(medicine, medClass, context);
          }).toList(),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Medicines',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF03045E),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...classSections,
      ],
    );
  }

  Widget _buildCollapsibleMedicineItem(Medicine medicine, String label, BuildContext context) {
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
        childrenPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
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
}