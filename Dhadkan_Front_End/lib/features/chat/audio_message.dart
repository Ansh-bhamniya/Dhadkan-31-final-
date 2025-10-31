// import 'dart:io';
// import 'package:dhadkan/utils/http/http_client.dart';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' as path;
// import 'package:record/record.dart';
// import 'package:mime/mime.dart';
// import 'package:http/http.dart' as http;
//
// class AudioMessage {
//   final String receiverId;
//   final String token;
//   final Record audioRecord = Record();
//
//   AudioMessage({
//     required this.receiverId,
//     required this.token,
//   });
//
//   Future<void> startRecording() async {
//     try {
//       if (await audioRecord.hasPermission()) {
//         await audioRecord.start(
//           encoder: AudioEncoder.aacLc,
//           bitRate: 128000,
//           samplingRate: 44100,
//         );
//       }
//     } catch (e) {
//       print("Recording error: $e");
//     }
//   }
//
//   Future<String?> stopRecording() async {
//     try {
//       return await audioRecord.stop();
//     } catch (e) {
//       print("Stop recording error: $e");
//       return null;
//     }
//   }
//
//   Future<void> uploadAudio(String filePath, BuildContext context) async {
//     try {
//       final mimeType = lookupMimeType(filePath);
//       final file = File(filePath);
//       final fileName = path.basename(filePath);
//
//       final response = await MyHttpHelper.private_multipart_post(
//         '/chat/upload-audio', // Changed endpoint for audio upload
//         {'audio': [file]}, // Changed field name to 'audio'
//         token,
//         {
//           'receiver_id': receiverId,
//           // 'message_type' is not needed here as the endpoint is specific to audio
//         },
//       );
//
//       if (response['success'] == true) {
//         // No SnackBar here, as the new message will be received via socket
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   const SnackBar(content: Text("Audio sent successfully!")),
//         // );
//       } else {
//         throw Exception("Upload failed: ${response['message']}"); // More detailed error
//       }
//     } catch (e) {
//       print("Audio upload error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to send audio")),
//       );
//     }
//   }
//
//   Future<void> cancelRecording() async {
//     try {
//       await audioRecord.stop();
//     } catch (e) {
//       print("Cancel recording error: $e");
//     }
//   }
// }