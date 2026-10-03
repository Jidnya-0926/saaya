import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/emergency_event_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<EmergencyEventModel> _events = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final box = StorageService.getHistoryBox();
    setState(() {
      _events = box.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  void _clearHistory() async {
    final box = StorageService.getHistoryBox();
    await box.clear();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency History"),
        actions: [
          if (_events.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _events.isEmpty
          ? const Center(
              child: Text(
                "No past emergency events recorded.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                final dateStr = DateFormat('MMM d, yyyy • hh:mm a').format(event.timestamp);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              event.triggerType,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: event.resolutionStatus == 'Resolved'
                                    ? AppTheme.safeGreen.withValues(alpha: 0.1)
                                    : AppTheme.emergencyRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.resolutionStatus,
                                style: TextStyle(
                                  color: event.resolutionStatus == 'Resolved'
                                      ? AppTheme.safeGreen
                                      : AppTheme.emergencyRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text("Contacts Notified: ${event.contactsNotifiedCount}"),
                        const SizedBox(height: 4),
                        Text("Location: ${event.locationSummary}", maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
