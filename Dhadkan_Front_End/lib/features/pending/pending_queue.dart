import 'package:shared_preferences/shared_preferences.dart';
import 'pending_patient.dart';

class PendingQueue {
  static const String _key = 'pending_add_patient_queue_v1';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> enqueue(PendingPatient p) async {
    await init();
    final list = List<String>.from(_prefs!.getStringList(_key) ?? const []);
    list.add(PendingPatient.encode(p));
    await _prefs!.setStringList(_key, list);
  }

  static List<PendingPatient> all() {
    final list = List<String>.from(_prefs?.getStringList(_key) ?? const []);
    final items = list.map(PendingPatient.decode).toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  static Future<void> remove(String id) async {
    await init();
    final list = List<String>.from(_prefs!.getStringList(_key) ?? const []);
    list.removeWhere((s) => PendingPatient.decode(s).id == id);
    await _prefs!.setStringList(_key, list);
  }

  static Future<void> bumpRetry(PendingPatient p) async {
    await init();
    final list = List<String>.from(_prefs!.getStringList(_key) ?? const []);
    for (int i = 0; i < list.length; i++) {
      final item = PendingPatient.decode(list[i]);
      if (item.id == p.id) {
        list[i] = PendingPatient.encode(item.copyWith(retryCount: item.retryCount + 1));
        break;
      }
    }
    await _prefs!.setStringList(_key, list);
  }

  static int length() {
    return (_prefs?.getStringList(_key) ?? const []).length;
  }
}


