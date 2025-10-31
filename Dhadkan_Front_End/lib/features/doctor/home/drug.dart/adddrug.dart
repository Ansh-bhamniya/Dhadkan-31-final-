import 'package:dhadkan/Custom/custom_elevated_button.dart';
import 'package:dhadkan/features/common/top_bar.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dhadkan/features/doctor/home/patient_drugdatascreen.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dhadkan/features/common/medicine_data.dart';
import 'dart:developer' as developer;

class AddDrugPage extends StatefulWidget {
  final String patientMobile;
  final PatientDrugRecord? record;
  final String? recordId;

  const AddDrugPage({
    super.key,
    required this.patientMobile,
    this.record,
    this.recordId,
  });

  @override
  State<AddDrugPage> createState() => _AddDrugPageState();
}

class _AddDrugPageState extends State<AddDrugPage> {
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
  final List<FocusNode> dropdownFocusNodesA = [];

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
  final List<FocusNode> dropdownFocusNodesB = [];

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
  final List<FocusNode> dropdownFocusNodesC = [];

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
  final List<FocusNode> dropdownFocusNodesD = [];

  // Options
  final List<String> frequencyOptions = [
    'Once a day',
    'Twice a day',
    'Thrice a day',
    'Four times a day',
    'Other'
  ];
  final List<String> timingOptions = ['Morning', 'HS', 'Other'];
  final List<String> formatOptions = ['Tablet', 'Syrup'];
  final List<String> statusOptions = ['Same', 'Better', 'Worse'];
  final List<String> yesNoOptions = ['Yes', 'No'];
  final List<String> diagnosisOptions = ['DCM', 'IHD with EF', 'HCM', 'NSAA', 'Other'];

  late stt.SpeechToText _speech;
  bool isListening = false;
  TextEditingController? currentListeningController;
  bool _isButtonLocked = false;
  final ScrollController _scrollController = ScrollController();
  Map<String, List<String>> _medicineCategories = {};

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initialize();
    _fetchMedicineCategories();
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
      _showErrorSnackbar(context, 'Error fetching medicine categories');
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
            if (!frequencyOptions.contains(currentFrequency) && currentFrequency.isNotEmpty) {
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
    dropdownFocusNodesA.clear();
    medicineControllersB.clear();
    dosageControllersB.clear();
    genericControllersB.clear();
    companyNameControllersB.clear();
    otherFrequencyControllersB.clear();
    formatValuesB.clear();
    frequencyValuesB.clear();
    timingValuesB.clear();
    otherTimingControllersB.clear();
    dropdownFocusNodesB.clear();
    medicineControllersC.clear();
    dosageControllersC.clear();
    genericControllersC.clear();
    companyNameControllersC.clear();
    otherFrequencyControllersC.clear();
    formatValuesC.clear();
    frequencyValuesC.clear();
    timingValuesC.clear();
    otherTimingControllersC.clear();
    dropdownFocusNodesC.clear();
    medicineControllersD.clear();
    dosageControllersD.clear();
    genericControllersD.clear();
    companyNameControllersD.clear();
    otherFrequencyControllersD.clear();
    formatValuesD.clear();
    frequencyValuesD.clear();
    timingValuesD.clear();
    otherTimingControllersD.clear();
    dropdownFocusNodesD.clear();
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
    FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      _scrollToFocusedField(context, focusNode);
    });

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
        dropdownFocusNodesA.add(focusNode);
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
        dropdownFocusNodesB.add(focusNode);
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
        dropdownFocusNodesC.add(focusNode);
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
        dropdownFocusNodesD.add(focusNode);
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
      onStatus: (status) => developer.log("Speech Status: $status"),
      onError: (error) {
        //print("Speech Error: $error");
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
    _scrollController.dispose();
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
    _disposeFocusNodeList(dropdownFocusNodesA);
    _disposeControllerList(medicineControllersB);
    _disposeControllerList(dosageControllersB);
    _disposeControllerList(genericControllersB);
    _disposeControllerList(companyNameControllersB);
    _disposeControllerList(otherFrequencyControllersB);
    _disposeControllerList(otherTimingControllersB);
    _disposeFocusNodeList(dropdownFocusNodesB);
    _disposeControllerList(medicineControllersC);
    _disposeControllerList(dosageControllersC);
    _disposeControllerList(genericControllersC);
    _disposeControllerList(companyNameControllersC);
    _disposeControllerList(otherFrequencyControllersC);
    _disposeControllerList(otherTimingControllersC);
    _disposeFocusNodeList(dropdownFocusNodesC);
    _disposeControllerList(medicineControllersD);
    _disposeControllerList(dosageControllersD);
    _disposeControllerList(genericControllersD);
    _disposeControllerList(companyNameControllersD);
    _disposeControllerList(otherFrequencyControllersD);
    _disposeControllerList(otherTimingControllersD);
    _disposeFocusNodeList(dropdownFocusNodesD);

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

  void _disposeFocusNodeList(List<FocusNode> focusNodes) {
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
  }

  void _addNewMedicineFields(String section, {bool isInitial = false}) {
    setState(() {
      TextEditingController nameCtrl = TextEditingController();
      TextEditingController dosageCtrl = TextEditingController();
      TextEditingController genericCtrl = TextEditingController();
      TextEditingController companyCtrl = TextEditingController();
      TextEditingController otherFreqCtrl = TextEditingController();
      TextEditingController otherTimingCtrl = TextEditingController();
      FocusNode focusNode = FocusNode();
      focusNode.addListener(() {
        _scrollToFocusedField(context, focusNode);
      });

      switch (section) {
        case 'A':
          medicineControllersA.add(nameCtrl);
          dosageControllersA.add(dosageCtrl);
          genericControllersA.add(genericCtrl);
          companyNameControllersA.add(companyCtrl);
          formatValuesA.add('Tablet');
          frequencyValuesA.add('Once a day');
          otherFrequencyControllersA.add(otherFreqCtrl);
          timingValuesA.add('Morning');
          otherTimingControllersA.add(otherTimingCtrl);
          dropdownFocusNodesA.add(focusNode);
          break;
        case 'B':
          medicineControllersB.add(nameCtrl);
          dosageControllersB.add(dosageCtrl);
          genericControllersB.add(genericCtrl);
          companyNameControllersB.add(companyCtrl);
          formatValuesB.add('Tablet');
          frequencyValuesB.add('Once a day');
          otherFrequencyControllersB.add(otherFreqCtrl);
          timingValuesB.add('Morning');
          otherTimingControllersB.add(otherTimingCtrl);
          dropdownFocusNodesB.add(focusNode);
          break;
        case 'C':
          medicineControllersC.add(nameCtrl);
          dosageControllersC.add(dosageCtrl);
          genericControllersC.add(genericCtrl);
          companyNameControllersC.add(companyCtrl);
          formatValuesC.add('Tablet');
          frequencyValuesC.add('Once a day');
          otherFrequencyControllersC.add(otherFreqCtrl);
          timingValuesC.add('Morning');
          otherTimingControllersC.add(otherTimingCtrl);
          dropdownFocusNodesC.add(focusNode);
          break;
        case 'D':
          medicineControllersD.add(nameCtrl);
          dosageControllersD.add(dosageCtrl);
          genericControllersD.add(genericCtrl);
          companyNameControllersD.add(companyCtrl);
          formatValuesD.add('Tablet');
          frequencyValuesD.add('Once a day');
          otherFrequencyControllersD.add(otherFreqCtrl);
          timingValuesD.add('Morning');
          otherTimingControllersD.add(otherTimingCtrl);
          dropdownFocusNodesD.add(focusNode);
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
          dropdownFocusNodesA.removeAt(index).dispose();
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
          dropdownFocusNodesB.removeAt(index).dispose();
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
          dropdownFocusNodesC.removeAt(index).dispose();
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
          dropdownFocusNodesD.removeAt(index).dispose();
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
          '/doctor/history/${widget.recordId}',
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
        'mobile': widget.patientMobile,
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
        '/doctor/adddrugpatient',
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
                ? 'Patient drug data updated successfully'
                : 'Patient drug data added successfully'),
          ),
        );
        Navigator.pushNamed(context, 'doctor/home/');
      } else {
        _showErrorSnackbar(context, response['message'] ?? 'Failed to process patient drug data');
        setState(() {
          _isButtonLocked = false;
        });
      }
    } catch (e) {
      //print('Submit error: $e');
      //print('Stack trace: $stackTrace');
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
        'frequency': frequencies[i] == 'Other' ? customFrequencies[i].text : frequencies[i],
        'generic': generics[i].text,
        'company_name': companies[i].text,
        'medicineTiming': timings[i] == 'Other' ? customTimings[i].text : timings[i],
      };
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

  Future<void> _showAddMedicineDialog(BuildContext context, String drugClass) async {
    final TextEditingController newMedicineController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
                      await _fetchMedicineCategories();
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

  void _scrollToFocusedField(BuildContext context, FocusNode focusNode) {
    if (focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (focusNode.context != null) {
          Scrollable.ensureVisible(
            focusNode.context!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      });
    }
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    bool isNumeric = false,
    bool enableSpeech = true,
  }) {
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      _scrollToFocusedField(context, focusNode);
    });
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
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
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      _scrollToFocusedField(context, focusNode);
    });
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          focusNode: focusNode,
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
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      _scrollToFocusedField(context, focusNode);
    });
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          focusNode: focusNode,
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
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      _scrollToFocusedField(context, focusNode);
    });
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          focusNode: focusNode,
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
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      _scrollToFocusedField(context, focusNode);
    });
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          focusNode: focusNode,
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
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      _scrollToFocusedField(context, focusNode);
    });
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          focusNode: focusNode,
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

  Widget _buildDiagnosisDropdown({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      _scrollToFocusedField(context, focusNode);
    });
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          focusNode: focusNode,
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
    required List<FocusNode> dropdownFocusNodes,
  }) {
    List<String> medicines = _medicineCategories[section] ?? [];

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
                Focus(
                  focusNode: dropdownFocusNodes[i],
                  child: DropdownSearch<String>(
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
                              Navigator.of(context).pop();
                              _showAddMedicineDialog(context, section);
                            },
                          ),
                        ),
                      ),
                      constraints: const BoxConstraints(maxHeight: 300),
                      menuProps: const MenuProps(
                        elevation: 8.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    items: medicines,
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MyDeviceUtils.getScreenWidth(context);
    return Scaffold(
      appBar: AppBar(
        title: TopBar(
          title: widget.record != null ? 'Edit Drug Data' : 'Add Drug Data',
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
              if (diagnosisValue == 'Other') ...[
                const SizedBox(height: 20),
                _buildTextFormField(
                  label: 'Specify Diagnosis',
                  controller: otherDiagnosisController,
                  isNumeric: false,
                  enableSpeech: true,
                ),
              ],
              const SizedBox(height: 20),
              _buildTextFormField(
                label: 'Weight',
                controller: weightController,
                isNumeric: true,
              ),
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
                dropdownFocusNodes: dropdownFocusNodesA,
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
                dropdownFocusNodes: dropdownFocusNodesB,
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
                dropdownFocusNodes: dropdownFocusNodesC,
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
                dropdownFocusNodes: dropdownFocusNodesD,
              ),
              const SizedBox(height: 30),
              CustomElevatedButton(
                text: widget.record != null ? 'Update Data' : 'Add Data',
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
}