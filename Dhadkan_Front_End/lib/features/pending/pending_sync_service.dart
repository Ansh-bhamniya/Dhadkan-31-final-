import 'dart:async';

import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:uuid/uuid.dart';

import 'pending_patient.dart';
import 'pending_queue.dart';

class PendingSyncService {
  static bool _initialized = false;
  static bool _isSyncing = false;
  static bool forceOffline = false; // Dev/testing toggle

  static Future<void> init() async {
    if (_initialized) return;
    await PendingQueue.init();
    _initialized = true;
  }

  static Future<void> enqueueFromForm({
    required String name,
    required String mobile,
    required String password,
    required String uhid,
    required int age,
    required String gender,
    String? email,
  }) async {
    await init();
    final p = PendingPatient(
      id: const Uuid().v4(),
      name: name,
      mobile: mobile,
      password: password,
      uhid: uhid,
      age: age,
      gender: gender,
      email: email,
      createdAt: DateTime.now(),
    );
    await PendingQueue.enqueue(p);
  }

  static Future<int> sync() async {
    await init();
    if (_isSyncing) return 0;
    _isSyncing = true;
    int successCount = 0;
    try {
      final token = await SecureStorageService.getData('authToken');
      if (token == null) return 0;

      final items = PendingQueue.all();
      for (final p in items) {
        final payload = {
          'name': p.name,
          'mobile': p.mobile,
          'password': p.password,
          'uhid': p.uhid,
          'age': p.age,
          'gender': p.gender,
          'email': p.email,
        };

        try {
          final res = await MyHttpHelper.private_post('/doctor/addpatient', payload, token);
          final ok = (res['status'] == 'success') || (res['success'] == true) || (res['success'] == 'true');
          final duplicate = (res['message']?.toString().toLowerCase().contains('exists') ?? false);
          if (ok || duplicate) {
            await PendingQueue.remove(p.id);
            successCount++;
          } else {
            await PendingQueue.bumpRetry(p);
          }
        } catch (_) {
          await PendingQueue.bumpRetry(p);
        }
      }
    } finally {
      _isSyncing = false;
    }
    return successCount;
  }
}


