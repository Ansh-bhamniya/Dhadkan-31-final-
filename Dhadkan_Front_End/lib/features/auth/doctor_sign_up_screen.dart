import 'package:dhadkan/utils/constants/colors.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:developer' as developer;

class DoctorSignUpScreen extends StatefulWidget {
  const DoctorSignUpScreen({super.key});

  @override
  State<DoctorSignUpScreen> createState() => _DoctorSignUpScreenState();
}

class _DoctorSignUpScreenState extends State<DoctorSignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();

  late stt.SpeechToText _speech;
  bool isListening = false;
  TextEditingController? currentListeningController;
  bool _obscurePassword = true;

  bool _isSubmitting = false;

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
      //print("Speech recognition is not available.");
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
    if (_isSubmitting) return; // Prevent multiple calls
    setState(() {
      _isSubmitting = true; // Lock the button
    });

    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String hospital = hospitalController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty || hospital.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      setState(() {
        _isSubmitting = false; // Unlock the button
      });
      return;
    }

    try {
      Map<String, dynamic> response =
      await MyHttpHelper.post('/doctor/signup', {
        'name': name,
        'mobile': phone,
        'password': password,
        'hospital': hospital,
        'email': email,
      });

      //print(response);
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
      _isSubmitting = false; // Unlock the button after process
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
          'Doctor Registration',
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
              Text(
                'Sign-Up As a Doctor',
                style: MyTextTheme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              _buildTextFormField(label: 'Name', controller: nameController),
              const SizedBox(height: 10),
              _buildTextFormField(label: 'Phone', controller: phoneController),
              const SizedBox(height: 20),
              _buildTextFormField(label: 'Email', controller: emailController),
              const SizedBox(height: 20),
              _buildTextFormField(
                label: 'Password',
                controller: passwordController,
                isObscured: _obscurePassword,
                isPasswordField: true,
              ),
              const SizedBox(height: 20),
              _buildTextFormField(label: 'Hospital', controller: hospitalController),
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
                    _isSubmitting ? 'Registering...' : 'Register',
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

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    hospitalController.dispose();
    super.dispose();
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    bool isObscured = false,
    bool isPasswordField = false,
  }) {
    bool isMicListening = currentListeningController == controller && isListening;

    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPasswordField)
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
                color: isMicListening ? Colors.red : Colors.grey,
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
        ),
      ),
      keyboardType: label == 'Phone' ? TextInputType.number : TextInputType.text,
    );
  }
}
