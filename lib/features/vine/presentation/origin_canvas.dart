import 'package:flutter/material.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';
import 'canvas_node.dart';

/// The relationship graph canvas where journal entries can be dropped and
/// connected to form an "origin map" (缘起图).
class OriginCanvas extends StatefulWidget {
  final OriginMap? activeMap;
  final List<JournalEntry> allEntries;
  final void Function(OriginMap updatedMap) onMapChanged;
  final List<OriginMap> allMaps;
  final void Function(String? mapId) onActiveMapChanged;
  final void Function() onNewMap;
  final void Function(String mapId) onDeleteMap;

  const OriginCanvas({
    super.key,
    required this.activeMap,
    required this.allEntries,
    required this.onMapChanged,
    required this.allMaps,
    required this.onActiveMapChanged,
    required this.onNewMap,
    required this.onDeleteMap,
  });

  @override
  State<OriginCanvas> createState() => _OriginCanvasState();
}

class _OriginCanvasState extends State<OriginCanvas> {
  /// Entry ID that is the source of a new edge being drawn.
  String? _linkSourceId;

  JournalEntry? _entryById(String id) {
    return widget.allEntries.where((e) => e.id == id).firstOrNull;
  }

  void _addNodeAtPosition(JournalEntry entry, Offset localPosition) {
    if (widget.activeMap == null) return;
    final map = widget.activeMap!;
    // Don't add duplicate
    if (map.nodes.any((n) => n.entryId == entry.id)) return;

    final newNode = OriginMapNode(
      entryId: entry.id,
      x: localPosition.dx,
      y: localPosition.dy,
    );
    final updated = map.copyWith(nodes: [...map.nodes, newNode]);
    widget.onMapChanged(updated);
  }

  void _moveNode(String entryId, Offset delta) {
    if (widget.activeMap == null) return;
    final map = widget.activeMap!;
    final nodes = map.nodes.map((n) {
      if (n.entryId == entryId) {
        return n.copyWith(x: n.x + delta.dx, y: n.y + delta.dy);
      }
      return n;
    }).toList();
    widget.onMapChanged(map.copyWith(nodes: nodes));
  }

  void _onNodeTap(String entryId) {
    if (_linkSourceId == null) {
      // Start linking
      setState(() => _linkSourceId = entryId);
    } else if (_linkSourceId == entryId) {
      // Cancel linking
      setState(() => _linkSourceId = null);
    } else {
      // Complete the edge
      _addEdge(_linkSourceId!, entryId);
      setState(() => _linkSourceId = null);
    }
  }

  void _addEdge(String fromId, String toId) {
    if (widget.activeMap == null) return;
    final map = widget.activeMap!;
    // Don't add duplicate
    if (map.edges.any((e) => e.fromEntryId == fromId && e.toEntryId == toId)) {
      return;
    }
    final newEdge = OriginMapEdge(fromEntryId: fromId, toEntryId: toId);
    widget.onMapChanged(map.copyWith(edges: [...map.edges, newEdge]));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Canvas area
        Expanded(
          child: DragTarget<JournalEntry>(
            onAcceptWithDetails: (details) {
              final renderBox = context.findRenderObject() as RenderBox;
              final localPos = renderBox.globalToLocal(details.offset);
              _addNodeAtPosition(details.data, localPos + const Offset(50, 35));
            },
            builder: (context, candidateData, rejectedData) {
              final isReceiving = candidateData.isNotEmpty;
              return Container(
                decoration: BoxDecoration(
                  color: isReceiving
                      ? AppTheme.background.withOpacity(0.95)
                      : AppTheme.background,
                  border: Border(
                    left: BorderSide(
                      color: isReceiving
                          ? AppTheme.accentGold.withOpacity(0.5)
                          : AppTheme.border,
                      width: isReceiving ? 2 : 0.5,
                    ),
                  ),
                ),
                child: widget.activeMap == null
                    ? _buildEmptyState()
                    : _buildCanvas(),
              );
            },
          ),
        ),
        // Bottom toolbar
        _buildToolbar(context),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_outlined, size: 40, color: AppTheme.textSecondary),
          SizedBox(height: 12),
          Text(
            '选择或新建一个缘起图',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    final map = widget.activeMap!;

    // Build edge line data
    final edgeLines = <_EdgeLineData>[];
    for (final edge in map.edges) {
      final fromNode = map.nodes.where((n) => n.entryId == edge.fromEntryId).firstOrNull;
      final toNode = map.nodes.where((n) => n.entryId == edge.toEntryId).firstOrNull;
      if (fromNode != null && toNode != null) {
        edgeLines.add(_EdgeLineData(
          Offset(fromNode.x, fromNode.y),
          Offset(toNode.x, toNode.y),
        ));
      }
    }

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(400),
      minScale: 0.3,
      maxScale: 3.0,
      child: SizedBox(
        width: 2000,
        height: 2000,
        child: Stack(
          children: [
            // Grid background
            CustomPaint(
              size: const Size(2000, 2000),
              painter: _GridPainter(),
            ),
            // Edge lines
            CustomPaint(
              size: const Size(2000, 2000),
              painter: _CanvasEdgePainter(edges: edgeLines),
            ),
            // Nodes
            for (final node in map.nodes)
              if (_entryById(node.entryId) != null)
                CanvasNode(
                  key: ValueKey('canvas_${node.entryId}'),
                  entry: _entryById(node.entryId)!,
                  position: Offset(node.x, node.y),
                  isSelected: false,
                  isLinkSource: _linkSourceId == node.entryId,
                  onTap: () => _onNodeTap(node.entryId),
                  onPanUpdate: (delta) => _moveNode(node.entryId, delta),
                  onPanEnd: () {},
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.panel.withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: AppTheme.border, width: 0.5),
          left: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Map selector dropdown
          Expanded(
            child: widget.allMaps.isEmpty
                ? const Text(
                    '无缘起图',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: widget.activeMap?.id,
                      isExpanded: true,
                      icon: const SizedBox.shrink(),
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                      items: [
                        for (final m in widget.allMaps)
                          DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: widget.onActiveMapChanged,
                    ),
                  ),
          ),
          // New map button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            color: AppTheme.accentGold,
            tooltip: '新建缘起图',
            onPressed: widget.onNewMap,
          ),
          // Delete map button
          if (widget.activeMap != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppTheme.danger,
              tooltip: '删除缘起图',
              onPressed: () => widget.onDeleteMap(widget.activeMap!.id),
            ),
          // Link mode indicator
          if (_linkSourceId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 14, color: AppTheme.accentGold),
                  SizedBox(width: 4),
                  Text(
                    '连线中',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'serif',
                      color: AppTheme.accentGold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Subtle grid background for the canvas.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.border.withOpacity(0.15)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _EdgeLineData {
  final Offset from;
  final Offset to;
  _EdgeLineData(this.from, this.to);
}

/// Paints edges between canvas nodes as bezier curves.
class _CanvasEdgePainter extends CustomPainter {
  final List<_EdgeLineData> edges;

  _CanvasEdgePainter({required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentSepia.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      final path = Path();
      path.moveTo(edge.from.dx, edge.from.dy);
      final midX = (edge.from.dx + edge.to.dx) / 2;
      path.cubicTo(
          midX, edge.from.dy, midX, edge.to.dy, edge.to.dx, edge.to.dy);
      canvas.drawPath(path, paint);

      // Draw a small circle at the endpoint
      final dotPaint = Paint()
        ..color = AppTheme.accentSepia.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(edge.to, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_CanvasEdgePainter oldDelegate) => true;
}
