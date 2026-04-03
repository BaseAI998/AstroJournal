import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../../../providers/journal_provider.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  final Set<String> _deletingIds = {};
  int _pendingDeleteCount = 0;

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _confirmDelete() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('确认删除', style: Theme.of(ctx).textTheme.displayMedium),
        content: Text(
          '确定要删除选中的 $count 篇日记吗？此操作不可撤销。',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _deletingIds.addAll(_selectedIds);
        _pendingDeleteCount = _selectedIds.length;
        _selectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  void _onCardDeleteDone(String id) {
    _pendingDeleteCount--;
    if (_pendingDeleteCount <= 0) {
      final ids = Set<String>.from(_deletingIds);
      setState(() => _deletingIds.clear());
      ref.read(journalProvider.notifier).deleteEntries(ids);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _selectionMode
              ? _exitSelectionMode
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
        ),
        title: Text(
          _selectionMode ? '已选择 ${_selectedIds.length} 项' : '历史回望',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              onPressed: _selectedIds.isEmpty ? null : _confirmDelete,
            ),
        ],
      ),
      body: journalState.when(
        data: (entries) {
          if (entries.isEmpty && _deletingIds.isEmpty) {
            return const Center(child: Text('暂无历史记录'));
          }

          final chartEntries = entries.toList();
          final double screenHeight = MediaQuery.of(context).size.height;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: chartEntries.length,
              itemBuilder: (context, index) {
                final entry = chartEntries[index];
                final double cardHeight =
                    (screenHeight / 3) + (index % 4) * 30 - 30;

                return _HistoryCard(
                  key: ValueKey(entry.id),
                  entry: entry,
                  cardHeight: cardHeight,
                  selectionMode: _selectionMode,
                  isSelected: _selectedIds.contains(entry.id),
                  isDeleting: _deletingIds.contains(entry.id),
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(entry.id);
                    } else {
                      context.push('/history/detail/${entry.id}');
                    }
                  },
                  onLongPressConfirmed: () {
                    setState(() {
                      _selectionMode = true;
                      _selectedIds.add(entry.id);
                    });
                  },
                  onDeleteDone: () => _onCardDeleteDone(entry.id),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// 单张卡片 —— 独立管理按压缩放和删除消失动画
class _HistoryCard extends StatefulWidget {
  final JournalEntry entry;
  final double cardHeight;
  final bool selectionMode;
  final bool isSelected;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onLongPressConfirmed;
  final VoidCallback onDeleteDone;

  const _HistoryCard({
    super.key,
    required this.entry,
    required this.cardHeight,
    required this.selectionMode,
    required this.isSelected,
    required this.isDeleting,
    required this.onTap,
    required this.onLongPressConfirmed,
    required this.onDeleteDone,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard>
    with TickerProviderStateMixin {
  // 按压缩放 1.0 → 0.92
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  // 删除消失：高度收缩 + 淡出
  late final AnimationController _deleteCtrl;
  late final Animation<double> _deleteSize;
  late final Animation<double> _deleteOpacity;

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pressScale = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOutCubic),
    );

    _deleteCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _deleteSize = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _deleteCtrl, curve: Curves.easeInCubic),
    );
    _deleteOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _deleteCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _deleteCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDeleteDone();
    });

    if (widget.isDeleting) _deleteCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant _HistoryCard old) {
    super.didUpdateWidget(old);
    if (widget.isDeleting && !old.isDeleting) _deleteCtrl.forward();
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _deleteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizeTransition(
      sizeFactor: _deleteSize,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _deleteOpacity,
        child: ListenableBuilder(
          listenable: _pressCtrl,
          builder: (context, child) {
            return Transform.scale(scale: _pressScale.value, child: child);
          },
          child: Listener(
            onPointerDown: (_) => _pressCtrl.forward(),
            onPointerUp: (_) => _pressCtrl.reverse(),
            onPointerCancel: (_) => _pressCtrl.reverse(),
            child: GestureDetector(
              onTap: widget.onTap,
              onLongPress: () {
                if (!widget.selectionMode) widget.onLongPressConfirmed();
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: widget.isSelected
                      ? const BorderSide(color: AppTheme.accentGold, width: 2)
                      : BorderSide.none,
                ),
                clipBehavior: Clip.antiAlias,
                color: theme.cardColor,
                child: Container(
                  height: widget.cardHeight,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('MM-dd HH:mm')
                                  .format(widget.entry.capturedAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.entry.fortuneScore != null)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.selectionMode && widget.isSelected
                                    ? AppTheme.accentGold
                                    : theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.selectionMode && widget.isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 3),
                                      child: Icon(Icons.check,
                                          size: 12, color: Colors.white),
                                    ),
                                  Text(
                                    '运势 ${widget.entry.fortuneScore}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          widget.selectionMode && widget.isSelected
                                              ? Colors.white
                                              : theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black,
                                Colors.black,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.7, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Text(
                            widget.entry.bodyText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
