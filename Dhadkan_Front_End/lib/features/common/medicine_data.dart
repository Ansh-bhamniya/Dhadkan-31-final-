import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';

class MedicineData {
  static Map<String, List<String>> _medicineCategories = {
    'A': [],
    'B': [],
    'C': [],
    'D': [],
  };

  static Future<Map<String, List<String>>> getMedicineCategories() async {
    try {
      String? token = await SecureStorageService.getData('authToken');
      if (token == null) {
        //print('No authentication token found');
        return _medicineCategories;
      }

      final response = await MyHttpHelper.private_get('/drugs/get', token);
      //print('Drugs API Response: $response');

      if (response.containsKey('success') &&
          response['success'].toString() == "true") {
        List<dynamic> data = response['data'] ?? [];
        if (data.isEmpty) {
          //print('No drug data returned from API');
          return _medicineCategories;
        }

        _medicineCategories = {
          'A': List<String>.from(data.isNotEmpty ? data[0] : []),
          'B': List<String>.from(data.length > 1 ? data[1] : []),
          'C': List<String>.from(data.length > 2 ? data[2] : []),
          'D': List<String>.from(data.length > 3 ? data[3] : []),
        };
      } else {
        //print('API error: ${response['message'] ?? 'Unknown error'}');
        return _medicineCategories;
      }
    } catch (e) {
      //print('Error fetching medicine categories: $e');
      //print('Stack trace: $stackTrace');
      return _medicineCategories;
    }
    return _medicineCategories;
  }

  static Map<String, List<String>> get cachedMedicineCategories =>
      _medicineCategories;

  static Future<bool> addMedicine(String name, String drugClass) async {
    try {
      String? token = await SecureStorageService.getData('authToken');
      if (token == null) {
        //print('No authentication token found');
        return false;
      }

      final response = await MyHttpHelper.private_post(
        '/drugs/add',
        {'name': name, 'class': drugClass},
        token,
      );
      //print('Add Medicine Response: $response');

      if (response.containsKey('success') &&
          response['success'].toString() == "true") {
        _medicineCategories[drugClass] = [
          ..._medicineCategories[drugClass] ?? [],
          name
        ]..sort();
        return true;
      } else {
        //print('Add medicine error: ${response['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      //print('Error adding medicine: $e');
      //print('Stack trace: $stackTrace');
      return false;
    }
  }
}
