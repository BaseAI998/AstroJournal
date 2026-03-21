import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../providers/journal_provider.dart';

class HistoryDetailPage extends ConsumerStatefulWidget {
  final String entryId;

  const HistoryDetailPage({super.key, required this.entryId});

  @override
  ConsumerState<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends ConsumerState<HistoryDetailPage> {
  bool _isEditing = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showEditConfirmDialog(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('确认修改', style: Theme.of(context).textTheme.titleLarge),
          content: const Text('是否确定修改此篇记录？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isEditing = true;
                  _textController.text = entry.bodyText;
                });
              },
              child: Text('确定', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _saveEdit(JournalEntry entry) {
    final updatedEntry = JournalEntry(
      id: entry.id,
      profileId: entry.profileId,
      capturedAt: entry.capturedAt,
      bodyText: _textController.text,
      fortuneScore: entry.fortuneScore,
      astroSnapshot: entry.astroSnapshot,
      createdAt: entry.createdAt,
    );

    ref.read(journalProvider.notifier).updateEntry(updatedEntry);
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (journalState is AsyncData<List<JournalEntry>>)
            Builder(
              builder: (context) {
                final entries = journalState.value;
                final entry = entries.firstWhere((e) => e.id == widget.entryId, orElse: () => entries.first);

                if (_isEditing) {
                  return IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _saveEdit(entry),
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditConfirmDialog(entry),
                  );
                }
              },
            ),
        ],
      ),
      body: journalState.when(
        data: (entries) {
          final entryIndex = entries.indexWhere((e) => e.id == widget.entryId);
          if (entryIndex == -1) {
            return const Center(child: Text('记录不存在'));
          }
          final entry = entries[entryIndex];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(entry.capturedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.astroSnapshot ?? '月亮双子座 | 主要相位：金星拱木星',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isEditing)
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    autofocus: true,
                  )
                else
                  Text(
                    entry.bodyText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
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
