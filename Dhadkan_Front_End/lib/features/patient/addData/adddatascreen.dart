import 'package:dhadkan/Custom/custom_elevated_button.dart';
import 'package:dhadkan/features/common/top_bar.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dhadkan/features/common/medicine_data.dart';
import 'package:dhadkan/features/patient/home/patient_home_screen.dart' show PatientDrugRecord;
import 'dart:developer' as developer;

class AddData extends StatefulWidget {
  final PatientDrugRecord? record;
  final String? recordId;

  const AddData({
    super.key,
    this.record,
    this.recordId,
  });

  @override
  State<AddData> createState() => _AddDataState();
}

class _AddDataState extends State<AddData> {
  String _token = "";
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController sbpController = TextEditingController();
  final TextEditingController dbpController = TextEditingController();
  final TextEditingController hrController = TextEditingController();
  final TextEditingController otherDiagnosisController = TextEditingController();

  String? statusValue;
  String? canWalkValue;
  String? canClimbValue;
  String? diagnosisValue;

  // Medicine Section A
  final List<TextEditingController> medicineControllersA = [];
  final List<TextEditingController> dosageControllersA = [];
  final List<TextEditingController> genericControllersA = [];
  final List<TextEditingController> companyNameControllersA = [];
  final List<String> formatValuesA = [];
  final List<String> frequencyValuesA = [];
  final List<TextEditingController> otherFrequencyControllersA = [];
  final List<String> timingValuesA = [];
  final List<TextEditingController> otherTimingControllersA = [];

  // Medicine Section B
  final List<TextEditingController> medicineControllersB = [];
  final List<TextEditingController> dosageControllersB = [];
  final List<TextEditingController> genericControllersB = [];
  final List<TextEditingController> companyNameControllersB = [];
  final List<String> formatValuesB = [];
  final List<String> frequencyValuesB = [];
  final List<TextEditingController> otherFrequencyControllersB = [];
  final List<String> timingValuesB = [];
  final List<TextEditingController> otherTimingControllersB = [];

  // Medicine Section C
  final List<TextEditingController> medicineControllersC = [];
  final List<TextEditingController> dosageControllersC = [];
  final List<TextEditingController> genericControllersC = [];
  final List<TextEditingController> companyNameControllersC = [];
  final List<String> formatValuesC = [];
  final List<String> frequencyValuesC = [];
  final List<TextEditingController> otherFrequencyControllersC = [];
  final List<String> timingValuesC = [];
  final List<TextEditingController> otherTimingControllersC = [];

  // Medicine Section D
  final List<TextEditingController> medicineControllersD = [];
  final List<TextEditingController> dosageControllersD = [];
  final List<TextEditingController> genericControllersD = [];
  final List<TextEditingController> companyNameControllersD = [];
  final List<String> formatValuesD = [];
  final List<String> frequencyValuesD = [];
  final List<TextEditingController> otherFrequencyControllersD = [];
  final List<String> timingValuesD = [];
  final List<TextEditingController> otherTimingControllersD = [];

  // Options
  final List<String> frequencyOptions = ['Once a day', 'Twice a day', 'Thrice a day', 'Four times a day', 'Other'];
  final List<String> timingOptions = ['Morning', 'HS', 'Other'];
  final List<String> formatOptions = ['Tablet', 'Syrup'];
  final List<String> statusOptions = ['Same', 'Better', 'Worse'];
  final List<String> yesNoOptions = ['Yes', 'No'];
  final List<String> diagnosisOptions = ['DCM', 'IHD with EF', 'HCM', 'NSAA', 'Other'];

  late stt.SpeechToText _speech;
  bool isListening = false;
  TextEditingController? currentListeningController;
  bool _isButtonLocked = false;
  Map<String, List<String>> _medicineCategories = {}; // New state variable for medicine categories

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initialize();
    _fetchMedicineCategories(); // Fetch medicine categories once
    _autofillData();
  }

  Future<void> _fetchMedicineCategories() async {
    try {
      final categories = await MedicineData.getMedicineCategories();
      if (mounted) {
        setState(() {
          _medicineCategories = categories;
        });
      }
    } catch (e) {
      //print("Error fetching medicine categories: $e");
      // Handle error, e.g., show a snackbar
    }
  }

  void _autofillData() {
    if (widget.record != null) {
      final record = widget.record!;
      setState(() {
        diagnosisValue = record.diagnosis;
        if (record.diagnosis == 'Other') {
          otherDiagnosisController.text = record.otherDiagnosis ?? '';
        }
        weightController.text = record.weight?.toString() ?? '';
        sbpController.text = record.sbp?.toString() ?? '';
        dbpController.text = record.dbp?.toString() ?? '';
        hrController.text = record.hr?.toString() ?? '';
        statusValue = record.status;
        canWalkValue = record.canWalk;
        canClimbValue = record.canClimb;

        _clearMedicineControllers();

        record.medicines?.forEach((medicine) {
          final section = medicine.medClass;
          if (section != null) {
            String currentTiming = medicine.medicineTiming ?? 'Morning';
            String otherTimingText = '';
            if (!timingOptions.contains(currentTiming) && currentTiming.isNotEmpty) {
              otherTimingText = currentTiming;
              currentTiming = 'Other';
            } else if (currentTiming.isEmpty) {
              currentTiming = 'Morning';
            }

            String currentFrequency = medicine.frequency ?? 'Once a day';
            String otherFrequencyText = '';
            if (medicine.frequency == 'Other' && medicine.customFrequency != null && medicine.customFrequency!.isNotEmpty) {
              otherFrequencyText = medicine.customFrequency!;
            } else if (!frequencyOptions.contains(currentFrequency) && currentFrequency.isNotEmpty) {
              otherFrequencyText = currentFrequency;
              currentFrequency = 'Other';
            } else if (currentFrequency.isEmpty) {
              currentFrequency = 'Once a day';
            }

            _addPopulatedMedicineFields(
              section,
              medicine.name ?? '',
              medicine.format ?? 'Tablet',
              medicine.dosage ?? '',
              currentFrequency,
              otherFrequencyText,
              currentTiming,
              otherTimingText,
              medicine.generic ?? '',
              medicine.companyName ?? '',
            );
          }
        });
        if (medicineControllersA.isEmpty) _addNewMedicineFields('A', isInitial: true);
        if (medicineControllersB.isEmpty) _addNewMedicineFields('B', isInitial: true);
        if (medicineControllersC.isEmpty) _addNewMedicineFields('C', isInitial: true);
        if (medicineControllersD.isEmpty) _addNewMedicineFields('D', isInitial: true);
      });
    } else {
      _addNewMedicineFields('A', isInitial: true);
      _addNewMedicineFields('B', isInitial: true);
      _addNewMedicineFields('C', isInitial: true);
      _addNewMedicineFields('D', isInitial: true);
    }
  }

  void _clearMedicineControllers() {
    medicineControllersA.clear();
    dosageControllersA.clear();
    genericControllersA.clear();
    companyNameControllersA.clear();
    otherFrequencyControllersA.clear();
    formatValuesA.clear();
    frequencyValuesA.clear();
    timingValuesA.clear();
    otherTimingControllersA.clear();
    medicineControllersB.clear();
    dosageControllersB.clear();
    genericControllersB.clear();
    companyNameControllersB.clear();
    otherFrequencyControllersB.clear();
    formatValuesB.clear();
    frequencyValuesB.clear();
    timingValuesB.clear();
    otherTimingControllersB.clear();
    medicineControllersC.clear();
    dosageControllersC.clear();
    genericControllersC.clear();
    companyNameControllersC.clear();
    otherFrequencyControllersC.clear();
    formatValuesC.clear();
    frequencyValuesC.clear();
    timingValuesC.clear();
    otherTimingControllersC.clear();
    medicineControllersD.clear();
    dosageControllersD.clear();
    genericControllersD.clear();
    companyNameControllersD.clear();
    otherFrequencyControllersD.clear();
    formatValuesD.clear();
    frequencyValuesD.clear();
    timingValuesD.clear();
    otherTimingControllersD.clear();
  }

  void _addPopulatedMedicineFields(
      String section,
      String name,
      String format,
      String dosage,
      String frequency,
      String customFrequency,
      String timing,
      String customTiming,
      String generic,
      String company) {
    TextEditingController nameCtrl = TextEditingController(text: name);
    TextEditingController dosageCtrl = TextEditingController(text: dosage);
    TextEditingController genericCtrl = TextEditingController(text: generic);
    TextEditingController companyCtrl = TextEditingController(text: company);
    TextEditingController otherFreqCtrl = TextEditingController(text: customFrequency);
    TextEditingController otherTimingCtrl = TextEditingController(text: customTiming);

    switch (section) {
      case 'A':
        medicineControllersA.add(nameCtrl);
        dosageControllersA.add(dosageCtrl);
        genericControllersA.add(genericCtrl);
        companyNameControllersA.add(companyCtrl);
        formatValuesA.add(format);
        frequencyValuesA.add(frequency);
        otherFrequencyControllersA.add(otherFreqCtrl);
        timingValuesA.add(timing);
        otherTimingControllersA.add(otherTimingCtrl);
        break;
      case 'B':
        medicineControllersB.add(nameCtrl);
        dosageControllersB.add(dosageCtrl);
        genericControllersB.add(genericCtrl);
        companyNameControllersB.add(companyCtrl);
        formatValuesB.add(format);
        frequencyValuesB.add(frequency);
        otherFrequencyControllersB.add(otherFreqCtrl);
        timingValuesB.add(timing);
        otherTimingControllersB.add(otherTimingCtrl);
        break;
      case 'C':
        medicineControllersC.add(nameCtrl);
        dosageControllersC.add(dosageCtrl);
        genericControllersC.add(genericCtrl);
        companyNameControllersC.add(companyCtrl);
        formatValuesC.add(format);
        frequencyValuesC.add(frequency);
        otherFrequencyControllersC.add(otherFreqCtrl);
        timingValuesC.add(timing);
        otherTimingControllersC.add(otherTimingCtrl);
        break;
      case 'D':
        medicineControllersD.add(nameCtrl);
        dosageControllersD.add(dosageCtrl);
        genericControllersD.add(genericCtrl);
        companyNameControllersD.add(companyCtrl);
        formatValuesD.add(format);
        frequencyValuesD.add(frequency);
        otherFrequencyControllersD.add(otherFreqCtrl);
        timingValuesD.add(timing);
        otherTimingControllersD.add(otherTimingCtrl);
        break;
    }
  }

  Future<void> _initialize() async {
    String? token = await SecureStorageService.getData('authToken');
    if (mounted) {
      setState(() {
        _token = token ?? '';
      });
    }
  }

  void startListening(TextEditingController controller) async {
    if (!await _speech.initialize(
      onStatus: (status) => developer.log("Status: $status"),
      onError: (error) {
        //print("Error: $error");
        _showErrorSnackbar(context, 'Speech recognition error: ${error.errorMsg}');
      },
    )) {
      _showErrorSnackbar(context, 'Speech recognition not available');
      return;
    }

    setState(() {
      isListening = true;
      currentListeningController = controller;
    });

    _speech.listen(
      onResult: (result) {
        setState(() {
          String correctedText = result.recognizedWords.toLowerCase();
          correctedText = correctedText.replaceAll(RegExp(r'\bmail\b', caseSensitive: false), 'male');
          controller.text = correctedText;
        });
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 20),
    );
    Future.delayed(const Duration(seconds: 5), () {
      if (isListening && currentListeningController == controller) {
        stopListening();
      }
    });
  }

  void stopListening() {
    _speech.stop();
    if (mounted) {
      setState(() {
        isListening = false;
        currentListeningController = null;
      });
    }
  }

  @override
  void dispose() {
    diagnosisController.dispose();
    otherDiagnosisController.dispose();
    weightController.dispose();
    sbpController.dispose();
    dbpController.dispose();
    hrController.dispose();

    _disposeControllerList(medicineControllersA);
    _disposeControllerList(dosageControllersA);
    _disposeControllerList(genericControllersA);
    _disposeControllerList(companyNameControllersA);
    _disposeControllerList(otherFrequencyControllersA);
    _disposeControllerList(otherTimingControllersA);
    _disposeControllerList(medicineControllersB);
    _disposeControllerList(dosageControllersB);
    _disposeControllerList(genericControllersB);
    _disposeControllerList(companyNameControllersB);
    _disposeControllerList(otherFrequencyControllersB);
    _disposeControllerList(otherTimingControllersB);
    _disposeControllerList(medicineControllersC);
    _disposeControllerList(dosageControllersC);
    _disposeControllerList(genericControllersC);
    _disposeControllerList(companyNameControllersC);
    _disposeControllerList(otherFrequencyControllersC);
    _disposeControllerList(otherTimingControllersC);
    _disposeControllerList(medicineControllersD);
    _disposeControllerList(dosageControllersD);
    _disposeControllerList(genericControllersD);
    _disposeControllerList(companyNameControllersD);
    _disposeControllerList(otherFrequencyControllersD);
    _disposeControllerList(otherTimingControllersD);

    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  void _disposeControllerList(List<TextEditingController> controllers) {
    for (var controller in controllers) {
      controller.dispose();
    }
  }

  void _addNewMedicineFields(String section, {bool isInitial = false}) {
    setState(() {
      switch (section) {
        case 'A':
          medicineControllersA.add(TextEditingController());
          dosageControllersA.add(TextEditingController());
          genericControllersA.add(TextEditingController());
          companyNameControllersA.add(TextEditingController());
          formatValuesA.add('Tablet');
          frequencyValuesA.add('Once a day');
          otherFrequencyControllersA.add(TextEditingController());
          timingValuesA.add('Morning');
          otherTimingControllersA.add(TextEditingController());
          break;
        case 'B':
          medicineControllersB.add(TextEditingController());
          dosageControllersB.add(TextEditingController());
          genericControllersB.add(TextEditingController());
          companyNameControllersB.add(TextEditingController());
          formatValuesB.add('Tablet');
          frequencyValuesB.add('Once a day');
          otherFrequencyControllersB.add(TextEditingController());
          timingValuesB.add('Morning');
          otherTimingControllersB.add(TextEditingController());
          break;
        case 'C':
          medicineControllersC.add(TextEditingController());
          dosageControllersC.add(TextEditingController());
          genericControllersC.add(TextEditingController());
          companyNameControllersC.add(TextEditingController());
          formatValuesC.add('Tablet');
          frequencyValuesC.add('Once a day');
          otherFrequencyControllersC.add(TextEditingController());
          timingValuesC.add('Morning');
          otherTimingControllersC.add(TextEditingController());
          break;
        case 'D':
          medicineControllersD.add(TextEditingController());
          dosageControllersD.add(TextEditingController());
          genericControllersD.add(TextEditingController());
          companyNameControllersD.add(TextEditingController());
          formatValuesD.add('Tablet');
          frequencyValuesD.add('Once a day');
          otherFrequencyControllersD.add(TextEditingController());
          timingValuesD.add('Morning');
          otherTimingControllersD.add(TextEditingController());
          break;
      }
    });
  }

  void _removeMedicineFields(String section, int index) {
    if (section == 'A' && medicineControllersA.length <= 1 && index == 0) return;
    if (section == 'B' && medicineControllersB.length <= 1 && index == 0) return;
    if (section == 'C' && medicineControllersC.length <= 1 && index == 0) return;
    if (section == 'D' && medicineControllersD.length <= 1 && index == 0) return;

    setState(() {
      switch (section) {
        case 'A':
          medicineControllersA.removeAt(index).dispose();
          dosageControllersA.removeAt(index).dispose();
          genericControllersA.removeAt(index).dispose();
          companyNameControllersA.removeAt(index).dispose();
          otherFrequencyControllersA.removeAt(index).dispose();
          formatValuesA.removeAt(index);
          frequencyValuesA.removeAt(index);
          timingValuesA.removeAt(index);
          otherTimingControllersA.removeAt(index).dispose();
          break;
        case 'B':
          medicineControllersB.removeAt(index).dispose();
          dosageControllersB.removeAt(index).dispose();
          genericControllersB.removeAt(index).dispose();
          companyNameControllersB.removeAt(index).dispose();
          otherFrequencyControllersB.removeAt(index).dispose();
          formatValuesB.removeAt(index);
          frequencyValuesB.removeAt(index);
          timingValuesB.removeAt(index);
          otherTimingControllersB.removeAt(index).dispose();
          break;
        case 'C':
          medicineControllersC.removeAt(index).dispose();
          dosageControllersC.removeAt(index).dispose();
          genericControllersC.removeAt(index).dispose();
          companyNameControllersC.removeAt(index).dispose();
          otherFrequencyControllersC.removeAt(index).dispose();
          formatValuesC.removeAt(index);
          frequencyValuesC.removeAt(index);
          timingValuesC.removeAt(index);
          otherTimingControllersC.removeAt(index).dispose();
          break;
        case 'D':
          medicineControllersD.removeAt(index).dispose();
          dosageControllersD.removeAt(index).dispose();
          genericControllersD.removeAt(index).dispose();
          companyNameControllersD.removeAt(index).dispose();
          otherFrequencyControllersD.removeAt(index).dispose();
          formatValuesD.removeAt(index);
          frequencyValuesD.removeAt(index);
          timingValuesD.removeAt(index);
          otherTimingControllersD.removeAt(index).dispose();
          break;
      }
    });
  }

  Future<void> handleSubmit(BuildContext context) async {
    if (_isButtonLocked) return;

    setState(() {
      _isButtonLocked = true;
    });

    if (diagnosisValue == null) {
      _showErrorSnackbar(context, 'Please select a diagnosis');
      setState(() {
        _isButtonLocked = false;
      });
      return;
    }

    if (diagnosisValue == 'Other' && otherDiagnosisController.text.trim().isEmpty) {
      _showErrorSnackbar(context, 'Please specify a diagnosis for "Other"');
      setState(() {
        _isButtonLocked = false;
      });
      return;
    }

    try {
      if (widget.record != null && widget.recordId != null) {
        final deleteResponse = await MyHttpHelper.private_delete(
          '/patient/history/${widget.recordId}',
          _token,
        );

        if (!(deleteResponse.containsKey('success') && deleteResponse['success'] == "true")) {
          _showErrorSnackbar(context, deleteResponse['message'] ?? 'Failed to delete existing data for update');
          setState(() {
            _isButtonLocked = false;
          });
          return;
        }
      }

      final patientData = {
        'diagnosis': diagnosisValue!,
        'otherDiagnosis': diagnosisValue == 'Other' ? otherDiagnosisController.text.trim() : '',
        'weight': weightController.text.isNotEmpty ? weightController.text : null,
        'sbp': sbpController.text.isNotEmpty ? sbpController.text : null,
        'dbp': dbpController.text.isNotEmpty ? dbpController.text : null,
        'hr': hrController.text.isNotEmpty ? hrController.text : null,
        'status': statusValue,
        'can_walk': canWalkValue,
        'can_climb': canClimbValue,
        'medicines': [
          ..._buildMedicineList('A', medicineControllersA, formatValuesA, dosageControllersA, frequencyValuesA, otherFrequencyControllersA, genericControllersA, companyNameControllersA, timingValuesA, otherTimingControllersA),
          ..._buildMedicineList('B', medicineControllersB, formatValuesB, dosageControllersB, frequencyValuesB, otherFrequencyControllersB, genericControllersB, companyNameControllersB, timingValuesB, otherTimingControllersB),
          ..._buildMedicineList('C', medicineControllersC, formatValuesC, dosageControllersC, frequencyValuesC, otherFrequencyControllersC, genericControllersC, companyNameControllersC, timingValuesC, otherTimingControllersC),
          ..._buildMedicineList('D', medicineControllersD, formatValuesD, dosageControllersD, frequencyValuesD, otherFrequencyControllersD, genericControllersD, companyNameControllersD, timingValuesD, otherTimingControllersD),
        ].where((medicine) => medicine['name'] != null && medicine['name'].isNotEmpty).toList(),
      };

      final response = await MyHttpHelper.private_post(
        '/patient/add',
        patientData,
        _token,
      );

      bool success = false;
      if (response.containsKey('success')) {
        if (response['success'] is bool) {
          success = response['success'];
        } else if (response['success'] is String) {
          success = response['success'].toLowerCase() == "true";
        }
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.record != null
                ? 'Patient data updated successfully'
                : 'Patient data added successfully'),
          ),
        );
        Navigator.pop(context);
      } else {
        _showErrorSnackbar(context, response['message'] ?? 'Failed to process patient data');
        setState(() {
          _isButtonLocked = false;
        });
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Error: ${e.toString()}');
      setState(() {
        _isButtonLocked = false;
      });
    }
  }

  List<Map<String, dynamic>> _buildMedicineList(
      String medicineClass,
      List<TextEditingController> medControllers,
      List<String> formats,
      List<TextEditingController> dosages,
      List<String> frequencies,
      List<TextEditingController> customFrequencies,
      List<TextEditingController> generics,
      List<TextEditingController> companies,
      List<String> timings,
      List<TextEditingController> customTimings) {
    return List.generate(medControllers.length, (i) {
      final medicine = {
        'name': medControllers[i].text,
        'class': medicineClass,
        'format': formats[i],
        'dosage': dosages[i].text,
        'frequency': frequencies[i],
        'generic': generics[i].text,
        'company_name': companies[i].text,
        'medicineTiming': timings[i] == 'Other' ? customTimings[i].text : timings[i],
      };

      if (frequencies[i] == 'Other' && customFrequencies[i].text.isNotEmpty) {
        medicine['customFrequency'] = customFrequencies[i].text;
      }
      return medicine;
    });
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Shows a dialog to add a new medicine.
  Future<void> _showAddMedicineDialog(BuildContext context, String drugClass) async {
    final TextEditingController newMedicineController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close.
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Medicine to Class $drugClass'),
          content: TextField(
            controller: newMedicineController,
            decoration: const InputDecoration(hintText: "Enter Medicine Name"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                final String newMedicineName = newMedicineController.text.trim();
                if (newMedicineName.isNotEmpty) {
                  final success = await MedicineData.addMedicine(newMedicineName, drugClass);
                  if (mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      await _fetchMedicineCategories(); // Re-fetch categories after adding a new one
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"$newMedicineName" added successfully.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to add medicine. It might already exist.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MyDeviceUtils.getScreenWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: TopBar(title: widget.record != null ? 'Edit Data' : 'Add Data'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildDiagnosisDropdown(
                label: 'Diagnosis',
                value: diagnosisValue,
                onChanged: (value) {
                  setState(() {
                    diagnosisValue = value;
                  });
                },
              ),
              if (diagnosisValue == 'Other')
                Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildTextFormField(
                      label: 'Specify Diagnosis',
                      controller: otherDiagnosisController,
                      isNumeric: false,
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _buildTextFormField(
                  label: 'Weight', controller: weightController, isNumeric: true),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                        label: 'SBP', controller: sbpController, isNumeric: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextFormField(
                        label: 'DBP', controller: dbpController, isNumeric: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextFormField(
                        label: 'HR', controller: hrController, isNumeric: true),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildStatusDropdown(
                label: 'Status',
                value: statusValue,
                onChanged: (value) {
                  setState(() {
                    statusValue = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildYesNoDropdown(
                label: 'Can Walk For 5 Min',
                value: canWalkValue,
                onChanged: (value) {
                  setState(() {
                    canWalkValue = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildYesNoDropdown(
                label: 'Can Climb Stairs',
                value: canClimbValue,
                onChanged: (value) {
                  setState(() {
                    canClimbValue = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildCollapsibleMedicineSection(
                medicineLabel: 'ACEi/ARBs/ARNIs/Isolazine',
                section: 'A',
                medicineControllers: medicineControllersA,
                formatValues: formatValuesA,
                dosageControllers: dosageControllersA,
                frequencyValues: frequencyValuesA,
                otherFrequencyControllers: otherFrequencyControllersA,
                genericControllers: genericControllersA,
                companyNameControllers: companyNameControllersA,
                timingValues: timingValuesA,
                otherTimingControllers: otherTimingControllersA,
              ),
              _buildCollapsibleMedicineSection(
                medicineLabel: 'Beta blockers, Ivabradine',
                section: 'B',
                medicineControllers: medicineControllersB,
                formatValues: formatValuesB,
                dosageControllers: dosageControllersB,
                frequencyValues: frequencyValuesB,
                otherFrequencyControllers: otherFrequencyControllersB,
                genericControllers: genericControllersB,
                companyNameControllers: companyNameControllersB,
                timingValues: timingValuesB,
                otherTimingControllers: otherTimingControllersB,
              ),
              _buildCollapsibleMedicineSection(
                medicineLabel: 'Complementary(SGLT-2 i, Blood thinner, STATINs, Fibrates, Bile acid sequestrants)',
                section: 'C',
                medicineControllers: medicineControllersC,
                formatValues: formatValuesC,
                dosageControllers: dosageControllersC,
                frequencyValues: frequencyValuesC,
                otherFrequencyControllers: otherFrequencyControllersC,
                genericControllers: genericControllersC,
                companyNameControllers: companyNameControllersC,
                timingValues: timingValuesC,
                otherTimingControllers: otherTimingControllersC,
              ),
              _buildCollapsibleMedicineSection(
                medicineLabel: 'Diuretics',
                section: 'D',
                medicineControllers: medicineControllersD,
                formatValues: formatValuesD,
                dosageControllers: dosageControllersD,
                frequencyValues: frequencyValuesD,
                otherFrequencyControllers: otherFrequencyControllersD,
                genericControllers: genericControllersD,
                companyNameControllers: companyNameControllersD,
                timingValues: timingValuesD,
                otherTimingControllers: otherTimingControllersD,
              ),
              const SizedBox(height: 30),
              CustomElevatedButton(
                text: widget.record != null ? "Update Data" : "Add Data",
                height: 40,
                onPressed: _isButtonLocked ? () {} : () => handleSubmit(context),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    bool isNumeric = false,
    bool enableSpeech = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: (!isNumeric && enableSpeech)
            ? IconButton(
          icon: Icon(
            Icons.mic,
            color: (currentListeningController == controller && isListening)
                ? Colors.red
                : Colors.grey,
          ),
          onPressed: () {
            if (isListening && currentListeningController == controller) {
              stopListening();
            } else {
              startListening(controller);
            }
          },
        )
            : null,
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
    );
  }

  Widget _buildFrequencyDropdown({
    required String label,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            labelStyle: const TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
          value: value,
          items: frequencyOptions.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimingDropdown({
    required String label,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            labelStyle: const TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
          value: value,
          items: timingOptions.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFormatDropdown({
    required String label,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            labelStyle: const TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
          value: value,
          items: formatOptions.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            labelStyle: const TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
          value: value,
          hint: const Text("Select status"),
          items: statusOptions.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildYesNoDropdown({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            labelStyle: const TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
          value: value,
          hint: const Text("Select"),
          items: yesNoOptions.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCollapsibleMedicineSection({
    required String medicineLabel,
    required String section,
    required List<TextEditingController> medicineControllers,
    required List<String> formatValues,
    required List<TextEditingController> dosageControllers,
    required List<String> frequencyValues,
    required List<TextEditingController> otherFrequencyControllers,
    required List<TextEditingController> genericControllers,
    required List<TextEditingController> companyNameControllers,
    required List<String> timingValues,
    required List<TextEditingController> otherTimingControllers,
  }) {
    List<String> medicines = _medicineCategories[section] ?? []; // Use the state variable directly

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          medicineLabel,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        children: [
          Column(
            children: [
              for (int i = 0; i < medicineControllers.length; i++) ...[
                DropdownSearch<String>(
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        labelText: 'Search Medicine',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dropdown
                            _showAddMedicineDialog(context, section);
                          },
                        ),
                      ),
                    ),
                  ),
                  items: medicines, // Use the pre-fetched list
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Medicine Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        medicineControllers[i].text = value;
                      });
                    }
                  },
                  selectedItem: medicineControllers[i].text.isNotEmpty
                      ? medicineControllers[i].text
                      : null,
                ),
                const SizedBox(height: 12),
                _buildFormatDropdown(
                  label: 'Format',
                  value: formatValues[i],
                  onChanged: (value) {
                    setState(() {
                      formatValues[i] = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildTextFormField(
                  label: 'Dosage',
                  controller: dosageControllers[i],
                  isNumeric: false,
                  enableSpeech: true,
                ),
                const SizedBox(height: 12),
                _buildFrequencyDropdown(
                  label: 'Frequency',
                  value: frequencyValues[i],
                  onChanged: (value) {
                    setState(() {
                      frequencyValues[i] = value!;
                    });
                  },
                ),
                if (frequencyValues[i] == 'Other')
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        label: 'Custom Frequency',
                        controller: otherFrequencyControllers[i],
                        isNumeric: false,
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _buildTimingDropdown(
                  label: 'Medicine Timing',
                  value: timingValues[i],
                  onChanged: (value) {
                    setState(() {
                      timingValues[i] = value!;
                    });
                  },
                ),
                if (timingValues[i] == 'Other')
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        label: 'Custom Timing',
                        controller: otherTimingControllers[i],
                        isNumeric: false,
                        enableSpeech: true,
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _buildTextFormField(
                  label: 'Generic',
                  controller: genericControllers[i],
                  isNumeric: false,
                ),
                const SizedBox(height: 12),
                _buildTextFormField(
                  label: 'Company Name',
                  controller: companyNameControllers[i],
                  isNumeric: false,
                ),
                const SizedBox(height: 12),
                if (i > 0 ||
                    (i == 0 &&
                        (section == 'A' && medicineControllersA.length > 1 ||
                            section == 'B' && medicineControllersB.length > 1 ||
                            section == 'C' && medicineControllersC.length > 1 ||
                            section == 'D' && medicineControllersD.length > 1)))
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                      WidgetStateProperty.all(const Color(0xFFFF5A5A)),
                      minimumSize:
                      WidgetStateProperty.all(const Size(double.infinity, 40)),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    onPressed: () => _removeMedicineFields(section, i),
                    child: const Text("Remove"),
                  ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 10),
              CustomElevatedButton(
                text: "Add More Medicine",
                height: 40,
                onPressed: () => _addNewMedicineFields(section),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisDropdown({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            labelStyle: const TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
          value: value,
          hint: const Text("Select diagnosis"),
          items: diagnosisOptions.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}