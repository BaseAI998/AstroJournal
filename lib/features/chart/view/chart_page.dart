import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/profile_provider.dart';
import '../model/chart_data.dart';
import '../service/astro_api_service.dart';
import 'chart_disc_painter.dart';

class ChartPage extends ConsumerStatefulWidget {
  const ChartPage({super.key});

  @override
  ConsumerState<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends ConsumerState<ChartPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;

  bool _showingNatal = true;
  double _dragDelta = 0;

  ChartData? _natalData;
  ChartData? _transitData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = CurvedAnimation(
      parent: _flipCtrl,
      curve: Curves.easeInOutCubic,
    );
    _flipCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showingNatal = !_showingNatal;
          _flipCtrl.reset();
        });
      }
    });

    // 延迟一帧后加载，确保 ref 可用
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCharts());
  }

  Future<void> _loadCharts() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) {
      setState(() {
        _loading = false;
        _error = '请先完善个人资料';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final birth = profile.birthDateTime;
    final city = profile.birthPlaceName;

    try {
      // 串行请求，免费套餐限制 1次/秒
      final natal = await AstroApiService.fetchNatalChart(
        year: birth.year,
        month: birth.month,
        day: birth.day,
        hour: birth.hour,
        minute: birth.minute,
        city: city,
      );

      // 等 1.2 秒再发第二个请求，避免触发限流
      await Future.delayed(const Duration(milliseconds: 1200));

      final transit = await AstroApiService.fetchTransitChart(
        natalYear: birth.year,
        natalMonth: birth.month,
        natalDay: birth.day,
        natalHour: birth.hour,
        natalMinute: birth.minute,
        city: city,
      );

      if (mounted) {
        setState(() {
          _natalData = natal;
          _transitData = transit;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '加载失败: $e';
          // 失败时用 mock 兜底
          _natalData = ChartData.mock();
          _transitData = ChartData.mock(isTransit: true);
        });
      }
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_flipCtrl.isAnimating) return;
    _dragDelta += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_flipCtrl.isAnimating) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDelta.abs() > 50 || velocity.abs() > 300) {
      _flipCtrl.forward();
    }
    _dragDelta = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                size: 20, color: AppTheme.textSecondary),
            onPressed: () async {
              await context.push('/profile');
              // 从 profile 页返回后重新加载
              _loadCharts();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentGold),
                  SizedBox(height: 16),
                  Text('正在计算星盘...',
                      style: TextStyle(
                          fontFamily: 'serif',
                          color: AppTheme.textSecondary)),
                ],
              ),
            )
          : SafeArea(
              child: GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final discSize = min(
                      constraints.maxHeight * 0.55,
                      constraints.maxWidth * 0.85,
                    );

                    final natalData = _natalData ?? ChartData.mock();
                    final transitData =
                        _transitData ?? ChartData.mock(isTransit: true);

                    return Column(
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 4),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.danger,
                                  fontFamily: 'serif'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 4),
                        ListenableBuilder(
                          listenable: _flipAnim,
                          builder: (context, _) {
                            final showNatal = _flipAnim.value < 0.5
                                ? _showingNatal
                                : !_showingNatal;
                            return Text(
                              showNatal ? '本命盘' : '行运盘',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium,
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '← 滑动翻转 →',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    AppTheme.textSecondary.withOpacity(0.5),
                                fontSize: 11,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Flipping disc
                        SizedBox(
                          width: discSize,
                          height: discSize,
                          child: ListenableBuilder(
                            listenable: _flipAnim,
                            builder: (context, _) {
                              final angle = _flipAnim.value * pi;
                              final showFront = angle < pi / 2;
                              final data = showFront
                                  ? (_showingNatal
                                      ? natalData
                                      : transitData)
                                  : (_showingNatal
                                      ? transitData
                                      : natalData);
                              final effectiveAngle =
                                  showFront ? angle : pi - angle;

                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(effectiveAngle),
                                child: CustomPaint(
                                  size: Size(discSize, discSize),
                                  painter:
                                      ChartDiscPainter(data: data),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info cards
                        Expanded(
                          child: ListenableBuilder(
                            listenable: _flipAnim,
                            builder: (context, _) {
                              final showNatal = _flipAnim.value < 0.5
                                  ? _showingNatal
                                  : !_showingNatal;
                              final data = showNatal
                                  ? natalData
                                  : transitData;
                              return _buildInfoCards(
                                  context, data, showNatal);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCards(
      BuildContext context, ChartData data, bool isNatal) {
    final sun = data.sun;
    final moon = data.moon;
    final asc = data.ascendant;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey(isNatal),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (sun != null) _buildBigThree(context, '太阳', sun),
                if (moon != null) _buildBigThree(context, '月亮', moon),
                if (asc != null) _buildBigThree(context, '上升', asc),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final p in data.planets)
                      if (p.name != 'Sun' && p.name != 'Moon')
                        _buildPlanetChip(context, p),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigThree(
      BuildContext context, String label, PlanetPosition planet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          planet.signGlyph,
          style: const TextStyle(
            fontSize: 28,
            color: AppTheme.accentGold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          planet.signChinese,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          '${planet.degree.toStringAsFixed(1)}°',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildPlanetChip(BuildContext context, PlanetPosition planet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.panel.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: planet.retrograde
              ? AppTheme.danger.withOpacity(0.4)
              : AppTheme.border,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            planet.planetGlyph,
            style: TextStyle(
              fontSize: 14,
              color: planet.retrograde ? AppTheme.danger : AppTheme.accentGold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${planet.signGlyph} ${planet.degree.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'serif',
              color: AppTheme.textPrimary,
            ),
          ),
          if (planet.retrograde)
            const Text(
              ' R',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'serif',
                fontWeight: FontWeight.bold,
                color: AppTheme.danger,
              ),
            ),
        ],
      ),
    );
  }
}
