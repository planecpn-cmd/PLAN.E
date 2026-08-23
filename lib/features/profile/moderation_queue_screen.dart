import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/trip_tools_providers.dart';
import '../../repositories/trip_chat_repository.dart';
import '../../theme/theme.dart';

class ModerationQueueScreen extends ConsumerStatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  ConsumerState<ModerationQueueScreen> createState() =>
      _ModerationQueueScreenState();
}

class _ModerationQueueScreenState
    extends ConsumerState<ModerationQueueScreen> {
  late Future<List<TripModerationReport>> _reports;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _reports = ref.read(tripChatRepositoryProvider).getModerationQueue();
  }

  Future<void> _review(TripModerationReport report, String status) async {
    await ref.read(tripChatRepositoryProvider).reviewReport(
      reportId: report.id,
      status: status,
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Message moderation')),
    body: FutureBuilder<List<TripModerationReport>>(
      future: _reports,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to load moderation queue: ${snapshot.error}'),
            ),
          );
        }
        final reports = snapshot.data ?? const [];
        if (reports.isEmpty) {
          return const Center(child: Text('No message reports.'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${report.reason.toUpperCase()} · ${report.status}',
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(report.messageBody),
                      if (report.details?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text('Reporter notes: ${report.details}'),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _review(report, 'reviewing'),
                            child: const Text('Reviewing'),
                          ),
                          FilledButton(
                            onPressed: () => _review(report, 'resolved'),
                            child: const Text('Resolve'),
                          ),
                          TextButton(
                            onPressed: () => _review(report, 'dismissed'),
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
