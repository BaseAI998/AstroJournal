import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../providers/journal_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../core/widgets/burn_fade_effect.dart';

class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({super.key});

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTriggered = false;
  bool _showHintText = true;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveEntry() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final profileState = ref.read(profileProvider);
    final profileId = profileState.value?.id;
    if (profileId == null) return;

    final entry = JournalEntry(
      id: const Uuid().v4(),
      profileId: profileId,
      capturedAt: DateTime.now(),
      bodyText: text,
      fortuneScore: Random().nextInt(101), // 0 to 100
      createdAt: DateTime.now(),
    );

    ref.read(journalProvider.notifier).addEntry(entry);
    
    // Unfocus first to remove cursor before capturing
    _focusNode.unfocus();
    
    // Trigger the Stardust effect
    setState(() {
      _isTriggered = true;
      _showHintText = false;
    });
    
    // We remove the SnackBar because it overlays the beautiful stardust effect.
    // The effect itself serves as the visual feedback for saving.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '此刻月亮在双子座',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    onPressed: () => context.push('/history'),
                  ),
                ],
              ),
            ),
            // Input Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: BurnFadeEffect(
                  isTriggered: _isTriggered,
                  onCaptureComplete: () {
                    // Clear the text only after snapshot is taken
                    _textController.clear();
                  },
                  onAnimationComplete: () {
                    if (mounted) {
                      setState(() {
                        _isTriggered = false;
                        _showHintText = true;
                      });
                    }
                  },
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    expands: true,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      height: 1.8,
                    ),
                    decoration: InputDecoration(
                      hintText: _showHintText ? '此刻有什么想留下的？' : '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            // Send Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _saveEntry,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
