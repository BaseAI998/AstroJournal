import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/journal_provider.dart';

class HistoryDetailPage extends ConsumerWidget {
  final String entryId;

  const HistoryDetailPage({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('详情', style: Theme.of(context).textTheme.bodyMedium),
      ),
      body: journalState.when(
        data: (entries) {
          final entryIndex = entries.indexWhere((e) => e.id == entryId);
          if (entryIndex == -1) {
            return const Center(child: Text('记录不存在'));
          }
          final entry = entries[entryIndex];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(entry.capturedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (entry.fortuneScore != null)
                      Text(
                        '运势: ${entry.fortuneScore}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  entry.bodyText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
