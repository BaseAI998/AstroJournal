import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';
import 'vine_painter.dart';
import 'vine_node.dart';

/// The vertical vine timeline that displays journal entries as hanging nodes.
///
/// When [collapsed] is true the vine shrinks to a narrow strip showing only
/// date dots — suitable for the side panel when the canvas is open.
class VineTimeline extends StatelessWidget {
  final List<JournalEntry> entries;
  final Set<String> highlightedEntryIds;
  final bool collapsed;
  final void Function(JournalEntry entry) onEntryTap;
  final void Function(JournalEntry entry, Offset globalPosition)? onEntryDragEnd;

  const VineTimeline({
    super.key,
    required this.entries,
    required this.highlightedEntryIds,
    required this.collapsed,
    required this.onEntryTap,
    this.onEntryDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          collapsed ? '' : '暂无记录',
          style: const TextStyle(
            fontFamily: 'serif',
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    // Group entries by month
    final grouped = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      final key = DateFormat('yyyy年M月').format(entry.capturedAt);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    // Build flat list of items: month headers + entries
    final items = <_TimelineItem>[];
    for (final monthKey in grouped.keys) {
      items.add(_TimelineItem.header(monthKey));
      final monthEntries = grouped[monthKey]!;
      for (int i = 0; i < monthEntries.length; i++) {
        items.add(_TimelineItem.entry(monthEntries[i]));
      }
    }

    // Layout constants
    const nodeSpacing = 100.0; // vertical spacing between nodes
    const headerHeight = 40.0;
    const topPadding = 20.0;

    // Compute Y positions for painter
    final nodeYPositions = <double>[];
    final nodeIsLeft = <bool>[];
    final highlightedIndices = <int>{};
    double currentY = topPadding;
    int nodeIndex = 0;

    for (final item in items) {
      if (item.isHeader) {
        currentY += headerHeight;
      } else {
        currentY += nodeSpacing;
        nodeYPositions.add(currentY);
        final isLeft = nodeIndex % 2 == 0;
        nodeIsLeft.add(isLeft);
        if (highlightedEntryIds.contains(item.entry!.id)) {
          highlightedIndices.add(nodeIndex);
        }
        nodeIndex++;
      }
    }

    final totalHeight = currentY + nodeSpacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // The vine stem
                Positioned.fill(
                  child: CustomPaint(
                    painter: VinePainter(
                      nodeYPositions: nodeYPositions,
                      nodeIsLeft: nodeIsLeft,
                      highlightedIndices: highlightedIndices,
                      totalHeight: totalHeight,
                      collapsed: collapsed,
                    ),
                  ),
                ),
                // Month headers and nodes
                ..._buildPositionedItems(items, constraints, topPadding,
                    nodeSpacing, headerHeight),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPositionedItems(
    List<_TimelineItem> items,
    BoxConstraints constraints,
    double topPadding,
    double nodeSpacing,
    double headerHeight,
  ) {
    final widgets = <Widget>[];
    final centerX = constraints.maxWidth / 2;
    double currentY = topPadding;
    int nodeIndex = 0;

    for (final item in items) {
      if (item.isHeader) {
        currentY += headerHeight;
        // Month label on the vine
        widgets.add(Positioned(
          top: currentY - headerHeight + 8,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.panel.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Text(
                item.headerTitle!,
                style: TextStyle(
                  fontSize: collapsed ? 9 : 11,
                  fontFamily: 'serif',
                  color: AppTheme.accentSepia,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ));
      } else {
        currentY += nodeSpacing;
        final entry = item.entry!;
        final isLeft = nodeIndex % 2 == 0;
        final isHighlighted = highlightedEntryIds.contains(entry.id);

        // Position node to the left or right of center
        final double nodeLeft;
        final double nodeWidth;

        if (collapsed) {
          nodeWidth = 32;
          nodeLeft = isLeft ? centerX - 30 : centerX + 6;
        } else {
          nodeWidth = 160;
          nodeLeft = isLeft ? centerX - nodeWidth - 20 : centerX + 20;
        }

        final nodeWidget = VineNode(
          entry: entry,
          isLeft: isLeft,
          isHighlighted: isHighlighted,
          collapsed: collapsed,
          onTap: () => onEntryTap(entry),
        );

        // Wrap in LongPressDraggable for canvas drag
        widgets.add(Positioned(
          top: currentY - 40, // center the node on the Y position
          left: nodeLeft,
          width: nodeWidth,
          child: LongPressDraggable<JournalEntry>(
            data: entry,
            feedback: VineNodeDragFeedback(entry: entry),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: nodeWidget,
            ),
            child: nodeWidget,
          ),
        ));

        nodeIndex++;
      }
    }

    return widgets;
  }
}

class _TimelineItem {
  final String? headerTitle;
  final JournalEntry? entry;

  bool get isHeader => headerTitle != null;

  _TimelineItem.header(this.headerTitle) : entry = null;
  _TimelineItem.entry(this.entry) : headerTitle = null;
}
