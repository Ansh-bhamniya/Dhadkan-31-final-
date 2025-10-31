import 'dart:convert';
import 'dart:io';
import 'package:dhadkan/utils/helpers/alphaToNum.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as record_pkg;
import 'package:http/http.dart' as http;
import 'package:dhadkan/features/doctor/home/doctor_home.dart';
import 'package:dhadkan/utils/constants/colors.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:dhadkan/utils/theme/text_theme.dart';

class Patientadder extends StatefulWidget {
  const Patientadder({super.key});

  @override
  State<Patientadder> createState() => _PatientadderState();
}

class _PatientadderState extends State<Patientadder> {
  String _token = "";
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController uhidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? selectedGender;
  bool _obscurePassword = true;
  bool _isButtonLocked = false;

  final recorder = record_pkg.AudioRecorder();
  bool isRecording = false;
  TextEditingController? currentListeningController;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    String? token = await SecureStorageService.getData('authToken');
    if (mounted) {
      setState(() {
        _token = token ?? '';
      });
    }
    _generatePassword();
  }

  Future<void> startRecording(TextEditingController controller) async {
    bool hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }

    // Duration: 12s for Phone Number & UHID, 6s for others
    int maxSeconds = (controller == mobileController || controller == uhidController) ? 12 : 6;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_input.m4a';

    await recorder.start(
      record_pkg.RecordConfig(
        encoder: record_pkg.AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      isRecording = true;
      currentListeningController = controller;
    });

    final activeController = controller;
    Future.delayed(Duration(seconds: maxSeconds), () async {
      if (isRecording && currentListeningController == activeController) {
        await stopRecording(activeController);
        print("Recording automatically stopped after $maxSeconds seconds");
      }
    });
  }

  Future<void> stopRecording(TextEditingController controller) async {
    final path = await recorder.stop();
    setState(() => isRecording = false);
    if (path == null) return;

    final file = File(path);
    String responseText = await sendToBackend(file);

    // Process text based on field
    String processedText = responseText;
    if (controller == mobileController || controller == ageController || controller == uhidController) {
      processedText = PhoneNumberParser.textToPhoneNumber(responseText);
    }

    setState(() => controller.text = processedText);
    print("Field [${_getFieldName(controller)}] updated: $processedText");
  }

  // Helper to get field name for logging
  String _getFieldName(TextEditingController controller) {
    if (controller == mobileController) return "Phone Number";
    if (controller == ageController) return "Age";
    if (controller == nameController) return "Name";
    if (controller == passwordController) return "Password";
    if (controller == emailController) return "Email";
    if (controller == uhidController) return "UHID";
    return "Unknown Field";
  }

  Future<String> sendToBackend(File audioFile) async {
    final uri = Uri.parse("http://localhost:3000/voice/transcribe");
    final request = http.MultipartRequest("POST", uri)
      ..files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    print("Raw backend response: $respStr");

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      return data['text'] ?? '';
    } else {
      print("Backend error: $respStr");
      return '';
    }
  }

  void _generatePassword() {
    final name = nameController.text.trim();
    final mobile = mobileController.text.trim();

    String firstName = name.split(' ').first.toLowerCase();
    String namePart = firstName.length >= 4 ? firstName.substring(0, 4) : firstName;

    String mobileDigits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    String mobilePart = mobileDigits.length >= 4
        ? mobileDigits.substring(mobileDigits.length - 4)
        : mobileDigits;

    setState(() {
      passwordController.text = namePart + mobilePart;
    });
  }

  Future<void> handleAdd(BuildContext context) async {
    if (_isButtonLocked) return;

    setState(() {
      _isButtonLocked = true;
    });

    final String name = nameController.text.trim();
    final String? gender = selectedGender;
    final String mobile = mobileController.text.trim();
    final String ageText = ageController.text.trim();
    final String uhidText = uhidController.text.trim();
    final String password = passwordController.text.trim();
    final String email = emailController.text.trim();

    if (name.isEmpty || mobile.isEmpty || gender == null || password.isEmpty || ageText.isEmpty || uhidText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      setState(() {
        _isButtonLocked = false;
      });
      return;
    }

    int age;
    int uhid;
    try {
      age = int.parse(ageText);
      uhid = int.parse(uhidText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values')),
      );
      setState(() {
        _isButtonLocked = false;
      });
      return;
    }

    try {
      final response = await MyHttpHelper.private_post(
        '/doctor/addpatient',
        {
          'name': name,
          'mobile': mobile,
          'gender': gender,
          'age': age,
          'uhid': uhid,
          'password': password,
          'email': email
        },
        _token,
      );

      if (response['status'] == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'An error occurred.')),
        );
        setState(() {
          _isButtonLocked = false;
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient added successfully')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DoctorHome()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during registration')),
      );
      setState(() {
        _isButtonLocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MyDeviceUtils.getScreenWidth(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign-Up Information', style: MyTextTheme.textTheme.headlineSmall),
          const SizedBox(height: 10),
          _buildTextFormField(label: 'Name', controller: nameController, generatePasswordOnChange: true),
          const SizedBox(height: 20),
          _buildTextFormField(label: 'Phone Number', controller: mobileController, generatePasswordOnChange: true),
          const SizedBox(height: 20),
          _buildGenderDropdown(),
          const SizedBox(height: 20),
          _buildTextFormField(label: 'Age', controller: ageController),
          const SizedBox(height: 20),
          _buildTextFormField(label: 'UHID', controller: uhidController),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildTextFormField(label: 'Email', controller: emailController),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isButtonLocked ? null : () => handleAdd(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isButtonLocked
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add this Patient...', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    bool generatePasswordOnChange = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.mic,
            color: (currentListeningController == controller && isRecording) ? Colors.red : Colors.grey,
          ),
          onPressed: () {
            if (isRecording && currentListeningController == controller) {
              stopRecording(controller);
            } else {
              startRecording(controller);
            }
          },
        ),
      ),
      keyboardType: label == 'Age' || label == 'Phone Number' || label == 'UHID'
          ? TextInputType.number
          : TextInputType.text,
      onChanged: (value) {
        if (label == 'Phone Number' || label == 'Age' || label == 'UHID') {
          String processed = PhoneNumberParser.textToPhoneNumber(value);
          controller.text = processed;
          controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length));
        }
        if (generatePasswordOnChange) _generatePassword();
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: ['Male', 'Female', 'Other'].map((String gender) {
        return DropdownMenuItem<String>(
          value: gender,
          child: Text(gender, style: const TextStyle(color: Colors.black)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedGender = newValue;
        });
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            IconButton(
              icon: Icon(
                Icons.mic,
                color: (currentListeningController == passwordController && isRecording) ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                if (isRecording && currentListeningController == passwordController) {
                  stopRecording(passwordController);
                } else {
                  startRecording(passwordController);
                }
              },
            ),
          ],
        ),
      ),
      keyboardType: TextInputType.text,
    );
  }
}
