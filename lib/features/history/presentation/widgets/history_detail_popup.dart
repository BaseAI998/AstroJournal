import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/database.dart';
import '../../../../core/extensions/string_extension.dart';
import '../../utils/history_layout_helper.dart';

class HistoryDetailPopup extends StatelessWidget {
  final JournalEntry entry;
  final Offset tapPosition;
  final BoxConstraints constraints;
  final ScrollController scrollController;
  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;

  const HistoryDetailPopup({
    super.key,
    required this.entry,
    required this.tapPosition,
    required this.constraints,
    required this.scrollController,
    required this.scaleAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        double scrollOffset = scrollController.hasClients ? scrollController.offset : 0.0;
        double screenTapX = tapPosition.dx - scrollOffset;
        
        double left = HistoryLayoutHelper.calculateLeft(screenTapX, constraints.maxWidth, 260.0);
        double top = HistoryLayoutHelper.calculateTop(tapPosition.dy + 16.0, constraints.maxHeight, 190.0);
        
        return Positioned(
          left: left,
          top: top,
          child: child!,
        );
      },
      child: SizedBox(
        width: 260,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd').format(entry.capturedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '运势: ${entry.fortuneScore ?? 50}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    entry.bodyText.toSummary(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        context.push('/history/detail/${entry.id}');
                      },
                      child: const Text('查看详情'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
