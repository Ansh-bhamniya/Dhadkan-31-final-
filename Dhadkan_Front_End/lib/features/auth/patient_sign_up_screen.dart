import 'package:dhadkan/utils/constants/colors.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:developer' as developer;
import '../../utils/http/http_client.dart';

class PatientSignUpScreen extends StatefulWidget {
  const PatientSignUpScreen({super.key});

  @override
  _PatientSignUpScreenState createState() => _PatientSignUpScreenState();
}

class _PatientSignUpScreenState extends State<PatientSignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController uhidController = TextEditingController();
  String? selectedGender;
  final TextEditingController ageController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController doctorNumberController = TextEditingController();

  late stt.SpeechToText _speech;
  bool isListening = false;
  TextEditingController? currentListeningController;

  bool _obscurePassword = true;
  bool _isSubmitting = false; // 🔑 Added

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void startListening(TextEditingController controller) async {
    if (!await _speech.initialize(
      onStatus: (status) => developer.log("Status: $status"),
      onError: (error) => developer.log("Error: $error"),
    )) {
      // print("Speech recognition is not available.");
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

    Future.delayed(const Duration(seconds: 3), () {
      if (isListening && currentListeningController == controller) {
        stopListening();
      }
    });
  }

  void stopListening() {
    _speech.stop();
    setState(() {
      isListening = false;
      currentListeningController = null;
    });
  }

  Future<void> handleSignUp(BuildContext context) async {
    if (_isSubmitting) return; // Prevent duplicate submissions

    setState(() {
      _isSubmitting = true; // Lock the button
    });

    final String name = nameController.text.trim();
    final String uhid = uhidController.text.trim();
    final String? gender = selectedGender;
    final String age = ageController.text.trim();
    final String email = emailController.text.trim();
    final String phone = phoneController.text.trim();
    final String password = passwordController.text.trim();
    final String doctorName = doctorNameController.text.trim();
    final String doctorNumber = doctorNumberController.text.trim();

    if (name.isEmpty ||
        uhid.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        age.isEmpty ||
        doctorName.isEmpty ||
        doctorNumber.isEmpty ||
        gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')));
      setState(() {
        _isSubmitting = false; // Unlock if validation fails
      });
      return;
    }

    try {
      Map<String, dynamic> response =
      await MyHttpHelper.post('/patient/signup', {
        'name': name,
        'mobile': phone,
        'password': password,
        'uhid': uhid,
        'email': email,
        'age': age,
        'gender': gender,
        'doctor_mobile': doctorNumber
      });
      // print(response);
      if (response['success'] == 'true') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('landing', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Registration failed!'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('An error occurred during registration'),
      ));
    }

    setState(() {
      _isSubmitting = false; // Unlock after completion
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MyDeviceUtils.getScreenWidth(context);
    var paddingWidth = screenWidth * 0.05;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined),
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Patient Registration',
          style: MyTextTheme.textTheme.headlineSmall?.copyWith(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Personal Information', style: MyTextTheme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              _buildTextFormField(label: 'Name', controller: nameController),
              const SizedBox(height: 20),
              _buildTextFormField(label: 'UHID', controller: uhidController),
              const SizedBox(height: 20),
              _buildGenderDropdown(),
              const SizedBox(height: 20),
              _buildTextFormField(label: 'Age', controller: ageController),
              const SizedBox(height: 30),
              Text('Sign-Up Information', style: MyTextTheme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              _buildTextFormField(label: 'Email', controller: emailController),
              const SizedBox(height: 20),
              _buildTextFormField(label: 'Phone Number', controller: phoneController),
              const SizedBox(height: 20),
              _buildTextFormField(label: 'Password', controller: passwordController, isObscured: true),
              const SizedBox(height: 30),
              Text('Doctor Details', style: MyTextTheme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              _buildTextFormField(label: 'Doctor Name', controller: doctorNameController),
              const SizedBox(height: 20),
              _buildTextFormField(label: 'Doctor Number', controller: doctorNumberController),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => handleSignUp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'Signing Up...' : 'Sign Up',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    bool isObscured = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured ? _obscurePassword : false,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: isObscured
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            IconButton(
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
            ),
          ],
        )
            : IconButton(
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
        ),
      ),
      keyboardType: label == 'Age' || label == 'Phone Number' || label == 'Doctor Number'
          ? TextInputType.number
          : TextInputType.text,
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
          child: Text(
            gender,
            style: const TextStyle(color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedGender = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a gender';
        }
        return null;
      },
    );
  }
}