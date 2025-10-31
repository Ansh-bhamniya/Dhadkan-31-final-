import 'dart:convert';

class PendingPatient {
  final String id; // local UUID
  final String name;
  final String mobile;
  final String password;
  final String uhid;
  final int age;
  final String gender;
  final String? email;
  final DateTime createdAt;
  final int retryCount;

  const PendingPatient({
    required this.id,
    required this.name,
    required this.mobile,
    required this.password,
    required this.uhid,
    required this.age,
    required this.gender,
    this.email,
    required this.createdAt,
    this.retryCount = 0,
  });

  PendingPatient copyWith({int? retryCount}) => PendingPatient(
        id: id,
        name: name,
        mobile: mobile,
        password: password,
        uhid: uhid,
        age: age,
        gender: gender,
        email: email,
        createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'password': password,
        'uhid': uhid,
        'age': age,
        'gender': gender,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  static PendingPatient fromJson(Map<String, dynamic> j) => PendingPatient(
        id: j['id'] as String,
        name: j['name'] as String,
        mobile: j['mobile'] as String,
        password: j['password'] as String,
        uhid: j['uhid'] as String,
        age: (j['age'] as num).toInt(),
        gender: j['gender'] as String,
        email: j['email'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        retryCount: (j['retryCount'] ?? 0) as int,
      );

  static String encode(PendingPatient p) => jsonEncode(p.toJson());
  static PendingPatient decode(String s) => fromJson(jsonDecode(s));
}

// --- Screen to view pending requests ---
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pending_queue.dart';
import 'pending_sync_service.dart';

class PendingPatientScreen extends StatefulWidget {
  const PendingPatientScreen({super.key});

  @override
  State<PendingPatientScreen> createState() => _PendingPatientScreenState();
}

class _PendingPatientScreenState extends State<PendingPatientScreen> {
  @override
  void initState() {
    super.initState();
    PendingSyncService.init();
  }

  Future<void> _syncNow() async {
    await PendingSyncService.sync();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = PendingQueue.all();
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Add Patient Requests'),
        actions: [
          IconButton(
            onPressed: _syncNow,
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Now',
          )
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No pending requests'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = items[i];
                return ListTile(
                  title: Text('${p.name}  (${p.mobile})'),
                  subtitle: Text('UHID: ${p.uhid}  •  Age: ${p.age}  •  Gender: ${p.gender}\nCreated: ${fmt.format(p.createdAt)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('Status: Pending', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                  leading: CircleAvatar(child: Text(p.retryCount.toString())),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: _syncNow,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Sync Pending Now'),
          ),
        ),
      ),
    );
  }
}


