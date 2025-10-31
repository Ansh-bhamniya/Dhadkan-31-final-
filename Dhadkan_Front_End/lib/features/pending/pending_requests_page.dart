import 'package:dhadkan/features/pending/pending_queue.dart';
import 'package:dhadkan/features/pending/pending_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PendingRequestsPage extends StatefulWidget {
  const PendingRequestsPage({super.key});

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
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
                    children: [
                      const Text('Status: Pending', style: TextStyle(color: Colors.orange)),
                      Text('Retries: ${p.retryCount}')
                    ],
                  ),
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



