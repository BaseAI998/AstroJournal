import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/journal_provider.dart';
import 'widgets/history_line_chart.dart';
import 'widgets/history_detail_popup.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  Offset? _tapPosition;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSpotTap(int index, [Offset? position]) {
    if (_selectedIndex == index) {
      _animationController.reverse().then((_) {
        setState(() {
          _selectedIndex = null;
          _tapPosition = null;
        });
      });
    } else {
      setState(() {
        _selectedIndex = index;
        if (position != null) {
          _tapPosition = position;
        }
      });
      _animationController.forward(from: 0.0);
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('历史回望', style: Theme.of(context).textTheme.bodyMedium),
      ),
      body: journalState.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('暂无历史记录'));
          }

          final chartEntries = entries.reversed.toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final double minWidth = constraints.maxWidth - 32;
              final double dataWidth = chartEntries.length * 60.0;
              final double chartWidth = dataWidth > minWidth ? dataWidth : minWidth;

              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: HistoryLineChart(
                            chartEntries: chartEntries,
                            chartWidth: chartWidth,
                            selectedIndex: _selectedIndex,
                            scrollController: _scrollController,
                            onSpotTap: _onSpotTap,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                  if (_selectedIndex != null && _tapPosition != null)
                    HistoryDetailPopup(
                      entry: chartEntries[_selectedIndex!],
                      tapPosition: _tapPosition!,
                      constraints: constraints,
                      scrollController: _scrollController,
                      scaleAnimation: _scaleAnimation,
                      fadeAnimation: _fadeAnimation,
                    ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
