import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'upload_report.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:dhadkan/utils/constants/colors.dart';

// Report class
class Report {
  final String id;
  final String patient;
  final String mobile;
  final String time; // This will now typically be the UTC time from the main report object
  final Map<String, dynamic> files;
  final bool hasReports;

  Report({
    required this.id,
    required this.patient,
    required this.mobile,
    required this.time,
    required this.files,
    required this.hasReports,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['_id'] ?? '',
      patient: json['patient'] ?? '',
      mobile: json['mobile'] ?? '',
      time: json['time'] ?? '', // This might be UTC, use uploadedAtIST for display
      files: json['files'] ?? {},
      hasReports: json['hasReports'] ?? false,
    );
  }
}

// ReportFile class
class ReportFile {
  final String path;
  final String url;
  final String type;
  final String originalname;
  final int size;
  final String? comment;
  final DateTime uploadedAt; // This will be the UTC DateTime object from the backend
  final String? uploadedAtIST; // New field to store the formatted IST string
  final DateTime? reportTime;

  ReportFile({
    required this.path,
    required this.url,
    required this.type,
    required this.originalname,
    required this.size,
    this.comment,
    required this.uploadedAt,
    this.uploadedAtIST, // Add to constructor
    this.reportTime,
  });

  factory ReportFile.fromJson(Map<String, dynamic> json) {
    return ReportFile(
      path: json['path'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      originalname: json['originalname'] ?? '',
      size: json['size'] ?? 0,
      comment: json['comment'],
      uploadedAt: DateTime.parse(json['uploadedAt']), // Parse ISO string (likely UTC)
      uploadedAtIST: json['uploadedAtIST'], // Get the formatted IST string
      reportTime: json['reportTime'] != null ? DateTime.parse(json['reportTime']) : null,
    );
  }
}

class ReportPage extends StatefulWidget {
  final String patientId;

  const ReportPage({super.key, required this.patientId});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<Report?> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _fetchReport();
  }

  Future<Report?> _fetchReport() async {
    try {
      // print('Fetching report for patient: ${widget.patientId}');
      String? token = await SecureStorageService.getData('authToken');
      if (token == null) {
        //print('No auth token found');
        throw Exception('Authentication required. Please login again.');
      }

      final response = await MyHttpHelper.get("/reports/${widget.patientId}", token);

      // print('API Response: $response');

      if (response['success'] == false) {
        //print('API Error: ${response['message']}');
        if (response['message']?.contains('token') == true) {
          throw Exception('Authentication failed. Please login again.');
        }
        throw Exception(response['message'] ?? 'Unknown error');
      }

      if (response['error'] != null) {
        //print('API Error: ${response['error']}');
        throw Exception(response['error']);
      }

      if (response['report'] == null) {
        //print('No report data in response');
        return null;
      }

      //print('Report data found: ${response['report']}');
      return Report.fromJson(response['report']);
    } catch (e) {
      //print('Error fetching report: $e');
      throw Exception('Failed to load report: $e');
    }
  }

  void _navigateToUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadReportPage(patientId: widget.patientId),
      ),
    ).then((_) {
      setState(() {
        _reportFuture = _fetchReport();
      });
    });
  }

  // This function is no longer strictly needed for uploadedAtIST,
  // but can be kept for other DateTime objects if needed.
  // Changed format to exclude seconds.
  // String _formatDate(DateTime date) {
  //   try {
  //     return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  //   } catch (e) {
  //     return 'Date unavailable';
  //   }
  // }

  void _viewFile(String path, String type, String reportName) {
    // Use the url field from ReportFile if available, otherwise construct with mediaURL
    String filePath = path.startsWith('http') ? path : MyHttpHelper.mediaURL + path;
    //print('Viewing file: $filePath (type: $type, name: $reportName)');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileViewerScreen(
          filePath: filePath,
          fileType: type,
          reportName: reportName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1FF),
      appBar: AppBar(
        title: Text(
          'Medical Reports',
          style: MyTextTheme.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        backgroundColor: MyColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Report?>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _reportFuture = _fetchReport();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No reports found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToUpload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.data!.hasReports) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No reports uploaded yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToUpload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final report = snapshot.data!;
            final reportTypes = [
              {'key': 'opd_card', 'name': 'OPD Card', 'icon': Icons.badge},
              {'key': 'echo', 'name': 'Echo', 'icon': Icons.favorite},
              {'key': 'ecg', 'name': 'ECG', 'icon': Icons.monitor_heart},
              {'key': 'cardiac_mri', 'name': 'Cardiac MRI', 'icon': Icons.medical_services},
              {'key': 'bnp', 'name': 'BNP', 'icon': Icons.science},
              {'key': 'biopsy', 'name': 'Biopsy', 'icon': Icons.biotech},
              {'key': 'biochemistry_report', 'name': 'Biochemistry Report', 'icon': Icons.analytics},
            ];

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reportTypes.length,
                    itemBuilder: (context, index) {
                      final reportType = reportTypes[index];
                      final fileData = report.files[reportType['key']];

                      if (fileData == null) {
                        return const SizedBox.shrink();
                      }

                      final reportFile = ReportFile.fromJson(fileData);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _viewFile(reportFile.url, reportFile.type, reportType['name'] as String);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: MyColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        reportType['icon'] as IconData,
                                        color: MyColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reportType['name'] as String,
                                            style: MyTextTheme.textTheme.headlineMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          // Use uploadedAtIST for display, without seconds
                                          Text(
                                            'Uploaded: ${reportFile.uploadedAtIST != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(reportFile.uploadedAtIST!).toLocal()) : 'Date unavailable'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (reportFile.comment != null && reportFile.comment!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Comments: ${reportFile.comment!}', // Moved comment next to "Comments:"
                                          style: MyTextTheme.textTheme.bodyMedium, // Removed bold and applied to the whole line
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    _viewFile(reportFile.url, reportFile.type, reportType['name'] as String);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MyColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text(
                                    'View Report',
                                    style: MyTextTheme.textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToUpload,
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Upload New Report',
                          style: MyTextTheme.textTheme.titleMedium?.copyWith(
                            fontSize: 15.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

// FileViewerScreen class
class FileViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileType;
  final String reportName;

  const FileViewerScreen({
    super.key,
    required this.filePath,
    required this.fileType,
    required this.reportName,
  });

  @override
  _FileViewerScreenState createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.fileType == 'pdf') {
      _downloadAndSaveFile();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndSaveFile() async {
    try {
      //print('Downloading file from: ${widget.filePath}');
      String? token = await SecureStorageService.getData('authToken');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(widget.filePath),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final fileExtension = widget.fileType == 'pdf' ? 'pdf' : widget.fileType;
      final file = File('${tempDir.path}/${widget.reportName}.$fileExtension');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _localFilePath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      //print('Error downloading file: $e');
      setState(() {
        _errorMessage = 'Failed to load file: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_localFilePath != null) {
      File(_localFilePath!).delete().then((_) {
        //print('Temporary file deleted: $_localFilePath');
      }).catchError((e) {
        //print('Error deleting temporary file: $e');
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.reportName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : _errorMessage != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                  _downloadAndSaveFile();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        )
            : widget.fileType == 'pdf' && _localFilePath != null
            ? PDFView(
          filePath: _localFilePath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          onError: (error) {
            setState(() {
              _errorMessage = 'Failed to load PDF: $error';
            });
          },
          onPageError: (page, error) {
            setState(() {
              _errorMessage = 'Error on page $page: $error';
            });
          },
        )
            : InteractiveViewer(
          child: Image.network(
            widget.filePath,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
