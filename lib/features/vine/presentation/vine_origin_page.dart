import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../../../providers/journal_provider.dart';
import '../../../providers/origin_map_provider.dart';
import 'vine_timeline.dart';
import 'origin_canvas.dart';

/// The Vine + Origin-Map page — a bottom-nav tab alongside Capture and Chart.
///
/// Left panel: scrollable vine timeline with journal entry nodes.
/// Right panel (swipe to open): origin-map canvas for building relationship
/// graphs between entries.
class VineOriginPage extends ConsumerStatefulWidget {
  const VineOriginPage({super.key});

  @override
  ConsumerState<VineOriginPage> createState() => _VineOriginPageState();
}

class _VineOriginPageState extends ConsumerState<VineOriginPage>
    with SingleTickerProviderStateMixin {
  /// 0.0 = vine full-screen, 1.0 = canvas fully open (vine collapsed).
  late final AnimationController _slideController;
  late final Animation<double> _slideAnim;

  double _dragStartX = 0;
  bool _isDragging = false;

  static const double _vineCollapsedFraction = 0.30;
  static const double _snapThreshold = 0.3;

  bool get _isCanvasOpen => _slideAnim.value > 0.5;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final delta = details.globalPosition.dx - _dragStartX;
    final screenWidth = MediaQuery.of(context).size.width;
    final newValue =
        (_slideController.value - delta / screenWidth).clamp(0.0, 1.0);
    _slideController.value = newValue;
    _dragStartX = details.globalPosition.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      _slideController.animateTo(1.0);
    } else if (velocity > 300) {
      _slideController.animateTo(0.0);
    } else {
      _slideController.animateTo(
        _slideController.value > _snapThreshold ? 1.0 : 0.0,
      );
    }
  }

  void _toggleCanvas() {
    if (_isCanvasOpen) {
      _slideController.animateTo(0.0);
    } else {
      _slideController.animateTo(1.0);
    }
  }

  void _onNewMap() {
    final id = const Uuid().v4();
    final count = (ref.read(originMapListProvider).value?.length ?? 0) + 1;
    final map = OriginMap(
      id: id,
      name: '缘起图 $count',
      createdAt: DateTime.now(),
    );
    ref.read(originMapListProvider.notifier).saveOriginMap(map);
    ref.read(activeOriginMapIdProvider.notifier).state = id;
  }

  void _onDeleteMap(String mapId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('删除缘起图', style: Theme.of(ctx).textTheme.displayMedium),
        content: Text('确定要删除这个缘起图吗？',
            style: Theme.of(ctx).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(originMapListProvider.notifier).deleteOriginMap(mapId);
      if (ref.read(activeOriginMapIdProvider) == mapId) {
        ref.read(activeOriginMapIdProvider.notifier).state = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalProvider);
    final mapsState = ref.watch(originMapListProvider);
    final activeMapId = ref.watch(activeOriginMapIdProvider);
    final highlightedIds = ref.watch(activeOriginMapEntryIdsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListenableBuilder(
                listenable: _slideAnim,
                builder: (context, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isCanvasOpen ? '缘起图' : '时间藤萝',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isCanvasOpen
                              ? Icons.chevron_left
                              : Icons.hub_outlined,
                          color: AppTheme.accentGold,
                          size: 22,
                        ),
                        tooltip: _isCanvasOpen ? '收起画布' : '打开缘起图',
                        onPressed: _toggleCanvas,
                      ),
                    ],
                  );
                },
              ),
            ),
            // Body
            Expanded(
              child: journalState.when(
                data: (entries) =>
                    _buildBody(entries, mapsState, activeMapId, highlightedIds),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    List<JournalEntry> entries,
    AsyncValue<List<OriginMap>> mapsState,
    String? activeMapId,
    Set<String> highlightedIds,
  ) {
    final maps = mapsState.value ?? [];
    final activeMap = activeMapId != null
        ? maps.where((m) => m.id == activeMapId).firstOrNull
        : null;

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: ListenableBuilder(
        listenable: _slideAnim,
        builder: (context, _) {
          final slideValue = _slideAnim.value;
          final screenWidth = MediaQuery.of(context).size.width;

          final vineWidth = screenWidth *
              (1.0 - slideValue * (1.0 - _vineCollapsedFraction));
          final canvasWidth = screenWidth - vineWidth;

          return Row(
            children: [
              SizedBox(
                width: vineWidth,
                child: VineTimeline(
                  entries: entries,
                  highlightedEntryIds: highlightedIds,
                  collapsed: slideValue > 0.5,
                  onEntryTap: (entry) {
                    context.push('/history/detail/${entry.id}');
                  },
                ),
              ),
              if (canvasWidth > 1)
                SizedBox(
                  width: canvasWidth,
                  child: OriginCanvas(
                    activeMap: activeMap,
                    allEntries: entries,
                    allMaps: maps,
                    onMapChanged: (updatedMap) {
                      ref
                          .read(originMapListProvider.notifier)
                          .saveOriginMap(updatedMap);
                    },
                    onActiveMapChanged: (mapId) {
                      ref.read(activeOriginMapIdProvider.notifier).state =
                          mapId;
                    },
                    onNewMap: _onNewMap,
                    onDeleteMap: _onDeleteMap,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
