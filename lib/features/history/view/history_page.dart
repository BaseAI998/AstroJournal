import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/journal_provider.dart';
import '../../../core/database/database.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  void _onSpotTap(int index) {
    if (_selectedIndex == index) {
      _animationController.reverse().then((_) {
        setState(() {
          _selectedIndex = null;
        });
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward(from: 0.0);
    }
  }

  String _getSummary(String text) {
    if (text.length > 50) {
      return '${text.substring(0, 50)}...';
    }
    return text;
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

          // Chronological order for the chart (entries is newest first)
          final chartEntries = entries.reversed.toList();

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 100,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 20,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Theme.of(context).dividerColor.withOpacity(0.1),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < 0 || value.toInt() >= chartEntries.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final date = chartEntries[value.toInt()].capturedAt;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('MM/dd').format(date),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                    ),
                                  );
                                },
                                reservedSize: 30,
                                interval: 1,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                  );
                                },
                                interval: 20,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2), width: 1),
                              left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2), width: 1),
                              right: BorderSide.none,
                              top: BorderSide.none,
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: const LineTouchTooltipData(
                              // Using transparent to hide default tooltip
                            ),
                            handleBuiltInTouches: false,
                            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                              if (event is FlTapUpEvent && touchResponse != null && touchResponse.lineBarSpots != null) {
                                final spotIndex = touchResponse.lineBarSpots!.first.spotIndex;
                                _onSpotTap(spotIndex);
                              }
                            },
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartEntries.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), (e.value.fortuneScore ?? 50).toDouble());
                              }).toList(),
                              isCurved: true,
                              color: Theme.of(context).primaryColor,
                              barWidth: 2,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: _selectedIndex == index ? 6 : 4,
                                    color: Theme.of(context).primaryColor,
                                    strokeWidth: _selectedIndex == index ? 2 : 0,
                                    strokeColor: Theme.of(context).colorScheme.surface,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom spacing so chart isn't cramped
                  const SizedBox(height: 40),
                ],
              ),
              if (_selectedIndex != null)
                Positioned(
                  bottom: 60,
                  left: 24,
                  right: 24,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
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
                                  DateFormat('yyyy-MM-dd').format(chartEntries[_selectedIndex!].capturedAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '运势: ${chartEntries[_selectedIndex!].fortuneScore ?? 50}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getSummary(chartEntries[_selectedIndex!].bodyText),
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
                                  context.push('/history/detail/${chartEntries[_selectedIndex!].id}');
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}