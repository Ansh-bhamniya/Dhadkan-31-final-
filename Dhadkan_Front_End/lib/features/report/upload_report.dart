import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:dhadkan/utils/constants/colors.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:file_selector/file_selector.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:image_picker/image_picker.dart'; // Import the image_picker package

class UploadReportPage extends StatefulWidget {
  final String patientId;

  const UploadReportPage({super.key, required this.patientId});

  @override
  _UploadReportPageState createState() => _UploadReportPageState();
}

class _UploadReportPageState extends State<UploadReportPage> {
  final Map<String, File?> _selectedFiles = {
    'opd_card': null,
    'echo': null,
    'ecg': null,
    'cardiac_mri': null,
    'bnp': null,
    'biopsy': null,
    'biochemistry_report': null,
  };

  final Map<String, TextEditingController> _commentControllers = {
    'opd_card': TextEditingController(),
    'echo': TextEditingController(),
    'ecg': TextEditingController(),
    'cardiac_mri': TextEditingController(),
    'bnp': TextEditingController(),
    'biopsy': TextEditingController(),
    'biochemistry_report': TextEditingController(),
  };

  final Map<String, String> _fieldLabels = {
    'opd_card': 'OPD Card',
    'echo': 'Echo',
    'ecg': 'ECG',
    'cardiac_mri': 'Cardiac MRI',
    'bnp': 'BNP',
    'biopsy': 'Biopsy',
    'biochemistry_report': 'Biochemistry Report',
  };

  bool _isButtonLocked = false;
  final ImagePicker _picker = ImagePicker(); // Initialize ImagePicker

  @override
  void dispose() {
    // Dispose all comment controllers
    _commentControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    try {
      String? token = await SecureStorageService.getData('authToken');
      return token;
    } catch (e) {
      //print('Error retrieving auth token: $e');
      return null;
    }
  }

  Future<void> _pickFiles(String fieldName) async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'Images', extensions: ['jpg', 'jpeg', 'png']),
          const XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );

      if (file != null) {
        setState(() {
          _selectedFiles[fieldName] = File(file.path);
        });
      }
    } catch (e) {
      //print('Error picking files: $e');
    }
  }

  // New method to take a photo
  Future<void> _takePhoto(String fieldName) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedFiles[fieldName] = File(photo.path);
        });
      }
    } catch (e) {
      //print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to open camera: $e',
            style: MyTextTheme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadFiles() async {
    if (_isButtonLocked) return;

    setState(() {
      _isButtonLocked = true;
    });

    try {
      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw Exception('No authentication token found');
      }

      final Map<String, List<File>> filesToUpload = {};
      final Map<String, String> comments = {};

      _selectedFiles.forEach((key, file) {
        if (file != null) {
          filesToUpload[key] = [file];
          comments[key] = _commentControllers[key]!.text;
        }
      });

      if (filesToUpload.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select at least one file to upload',
              style: MyTextTheme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isButtonLocked = false;
        });
        return;
      }

      final response = await MyHttpHelper.private_multipart_post(
        '/reports/upload/${widget.patientId}',
        filesToUpload,
        authToken,
        comments, // Send comments as part of the form data
      );

      if (response['statusCode'] == 201 || response['success'] == true || (response.containsKey('success') && response['success'])) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Files uploaded successfully',
              style: MyTextTheme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: MyColors.primary,
          ),
        );
        Navigator.pop(context, true);
      } else if (response['statusCode'] == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authentication failed. Please login again.',
              style: MyTextTheme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        await SecureStorageService.deleteData('authToken');
        setState(() {
          _isButtonLocked = false;
        });
      } else {
        String errorMessage = response['error'] ?? response['message'] ?? 'Unknown error occurred';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload failed: $errorMessage',
              style: MyTextTheme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isButtonLocked = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload files: $e',
            style: MyTextTheme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isButtonLocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Medical Reports',
          style: MyTextTheme.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._selectedFiles.keys.map((field) => _buildFileUploadSection(
              _fieldLabels[field]!,
              field,
              _selectedFiles[field],
              _commentControllers[field]!,
            )),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isButtonLocked ? null : _uploadFiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isButtonLocked
                  ? const CircularProgressIndicator()
                  : Text(
                'Submit Reports',
                style: MyTextTheme.textTheme.titleMedium?.copyWith(
                  fontSize: 15.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection(String title, String fieldName, File? file, TextEditingController commentController) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: MyTextTheme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            if (file == null)
              Text(
                'No file selected',
                style: MyTextTheme.textTheme.bodyMedium,
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file),
                title: Text(
                  file.path.split('/').last,
                  style: MyTextTheme.textTheme.bodyMedium,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedFiles[fieldName] = null;
                    });
                  },
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Comments (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // Adjusted content padding for a shorter field
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: 1, // Reduced maxLines to 1 for a shorter field
            ),
            const SizedBox(height: 12),
            Row( // Use a Row to place buttons side-by-side
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickFiles(fieldName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      file == null ? 'Select File' : 'Change File',
                      style: MyTextTheme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Add some spacing between buttons
                Expanded(
                  child: ElevatedButton.icon( // Use ElevatedButton.icon for an icon and text
                    onPressed: () => _takePhoto(fieldName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt, color: Colors.white), // Camera icon
                    label: Text(
                      'Take Photo',
                      style: MyTextTheme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
