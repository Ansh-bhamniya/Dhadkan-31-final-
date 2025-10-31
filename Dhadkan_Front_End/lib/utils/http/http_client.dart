import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser; // Ensure correct import

class MyHttpHelper {
  // static const String _baseUrl = 'http://10.81.102.101:3000'; //local server
  static const String _baseUrl = 'http://192.168.106.2:3000'; // lab server 
  //  static const String _baseUrl = 'https://dhadkan-backend.onrender.com';
  static const mediaURL = "$_baseUrl/media/";

  static Future<Map<String, dynamic>> get(String endpoint, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, dynamic data) async {
    final response = await http.post(Uri.parse('$_baseUrl$endpoint/'),
        headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> private_post(
      String endpoint, dynamic data, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> private_delete(String endpoint, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> private_get(
      String endpoint, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> private_multipart_post(
      String endpoint, Map<String, List<File>> files, String token, Map<String, String> fields) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl$endpoint/'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    for (var field in files.keys) {
      for (var file in files[field]!) {
        final fileStream = http.ByteStream(Stream.castFrom(file.openRead()));
        final length = await file.length();
        final multipartFile = http.MultipartFile(
          field,
          fileStream,
          length,
          filename: file.path.split('/').last,
          contentType: file.path.endsWith('.pdf')
              ? http_parser.MediaType('application', 'pdf') // Use http_parser.MediaType
              : http_parser.MediaType('image', file.path.split('.').last), // Use http_parser.MediaType
        );
        request.files.add(multipartFile);
      }
    }

    request.fields.addAll(fields);

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    return _handleResponseData(response.statusCode, responseData);
  }

  static Map<String, dynamic> _handleResponseData(int statusCode, String responseData) {
    // print(statusCode);
    return json.decode(responseData);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    // print(response.statusCode);
    return json.decode(response.body);
  }
}