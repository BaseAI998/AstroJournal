import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';

/// A single journal entry node hanging off the vine.
///
/// In full mode: shows date, text preview, fortune badge.
/// In collapsed mode: shows only a date dot.
class VineNode extends StatefulWidget {
  final JournalEntry entry;
  final bool isLeft;
  final bool isHighlighted;
  final bool collapsed;
  final VoidCallback onTap;

  const VineNode({
    super.key,
    required this.entry,
    required this.isLeft,
    required this.isHighlighted,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<VineNode> createState() => _VineNodeState();
}

class _VineNodeState extends State<VineNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isHighlighted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant VineNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isHighlighted && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.collapsed) {
      return _buildCollapsedNode(context);
    }
    return _buildFullNode(context);
  }

  Widget _buildCollapsedNode(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ListenableBuilder(
        listenable: _pulseAnim,
        builder: (context, child) {
          final glowOpacity = widget.isHighlighted ? 0.3 + _pulseAnim.value * 0.4 : 0.0;
          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.panel,
              border: Border.all(
                color: widget.isHighlighted
                    ? AppTheme.accentGold
                    : AppTheme.border,
                width: widget.isHighlighted ? 2 : 1,
              ),
              boxShadow: widget.isHighlighted
                  ? [
                      BoxShadow(
                        color: AppTheme.accentGold.withOpacity(glowOpacity),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              DateFormat('dd').format(widget.entry.capturedAt),
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'serif',
                color: AppTheme.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullNode(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: ListenableBuilder(
        listenable: _pulseAnim,
        builder: (context, child) {
          final glowOpacity =
              widget.isHighlighted ? 0.2 + _pulseAnim.value * 0.35 : 0.0;
          return Container(
            width: 160,
            constraints: const BoxConstraints(minHeight: 80, maxHeight: 140),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.panel.withOpacity(0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isHighlighted
                    ? AppTheme.accentGold
                    : AppTheme.border,
                width: widget.isHighlighted ? 1.8 : 0.8,
              ),
              boxShadow: [
                if (widget.isHighlighted)
                  BoxShadow(
                    color: AppTheme.accentGold.withOpacity(glowOpacity),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date + fortune
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MM/dd HH:mm')
                          .format(widget.entry.capturedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (widget.entry.fortuneScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.entry.fortuneScore}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontFamily: 'serif',
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Body preview
                Flexible(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.black, Colors.transparent],
                        stops: [0.0, 0.65, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Text(
                      widget.entry.bodyText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Drag feedback shown when dragging a node to the canvas.
class VineNodeDragFeedback extends StatelessWidget {
  final JournalEntry entry;

  const VineNodeDragFeedback({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.panel.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentGold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          entry.bodyText,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'serif',
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
