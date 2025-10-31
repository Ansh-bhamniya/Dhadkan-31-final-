import 'package:dhadkan/Custom/custom_elevated_button.dart';
import 'package:dhadkan/features/auth/selection_screen.dart';
import 'package:dhadkan/features/common/wrapper.dart';
import 'package:dhadkan/features/doctor/home/doctor_home.dart';
import 'package:dhadkan/features/patient/home/patient_home_screen.dart';
import 'package:dhadkan/utils/constants/colors.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/helpers/helper_functions.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false; // 🔑 Added

  Future<void> handleLogin(BuildContext context) async {
    if (_isSubmitting) return; // Prevent duplicate submission

    setState(() {
      _isSubmitting = true; // Lock the button
    });

    final String mobile = mobileController.text.trim();
    final String password = passwordController.text;

    if (mobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')));
      setState(() {
        _isSubmitting = false; // Unlock on validation failure
      });
      return;
    }

    try {
      Map<String, dynamic> response = await MyHttpHelper.post(
          '/auth/login', {'mobile': mobile, 'password': password});
      if (response['success'] == "true") {
        String token = response['message'];
        String role = getRole(token);
        if (role.isEmpty) {
          throw Exception('Invalid role in token');
        }
        await SecureStorageService.storeData('authToken', token);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successful!")));
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) =>
              role == "patient" ? const PatientHome() : const DoctorHome()),
              (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Login failed')));
      }
    } catch (e) {
      //print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')));
    }

    setState(() {
      _isSubmitting = false; // Unlock the button after attempt
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MyDeviceUtils.getScreenWidth(context);

    return Scaffold(
      body: Wrapper(
        top: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Dhadkan',
                    style:
                    TextStyle(fontSize: 36, fontWeight: FontWeight.w600)),
                Text('App for Heart Disease',
                    style: MyTextTheme.textTheme.bodyMedium)
              ]),
              const SizedBox(width: 10),
              Image.asset('assets/Images/logo.png',
                  height: 70, width: 70, fit: BoxFit.cover),
            ]),
            const SizedBox(height: 55),
            Text('Login', style: MyTextTheme.textTheme.headlineLarge),
            const SizedBox(height: 24),
            TextFormField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              style: MyTextTheme.textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Phone Number',
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.phone),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 17, horizontal: 10),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Password',
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: MyColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: screenWidth * 0.9,
              height: 50,
              child: CustomElevatedButton(
                height: 50,
                // width: 20,
                onPressed: _isSubmitting ? () {} : () => handleLogin(context),
                text: _isSubmitting ? 'Logging in...' : 'Login',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Patient default password is the first 4 letters of name + last 4 digits of mobile number",
              style: MyTextTheme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: MyTextTheme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelectionScreen(),
                        ),
                      );
                    },
                    child: Text('Sign Up',
                        style: MyTextTheme.textTheme.headlineSmall),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}