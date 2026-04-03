import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';

/// A node placed on the OriginCanvas representing a journal entry.
class CanvasNode extends StatelessWidget {
  final JournalEntry entry;
  final Offset position;
  final bool isSelected;
  final bool isLinkSource;
  final VoidCallback onTap;
  final void Function(Offset delta) onPanUpdate;
  final void Function() onPanEnd;

  const CanvasNode({
    super.key,
    required this.entry,
    required this.position,
    required this.isSelected,
    required this.isLinkSource,
    required this.onTap,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 50,
      top: position.dy - 35,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (details) => onPanUpdate(details.delta),
        onPanEnd: (_) => onPanEnd(),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.panel.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLinkSource
                  ? AppTheme.accentGold
                  : isSelected
                      ? AppTheme.accentSepia
                      : AppTheme.border,
              width: (isSelected || isLinkSource) ? 2 : 0.8,
            ),
            boxShadow: [
              if (isLinkSource)
                BoxShadow(
                  color: AppTheme.accentGold.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MM/dd').format(entry.capturedAt),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentSepia,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.bodyText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'serif',
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

