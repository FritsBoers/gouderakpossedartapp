import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';

/// Bar chart showing player stats overview.
class StatsChart extends StatelessWidget {
  final PlayerStats stats;

  const StatsChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${_labels[groupIndex]}\n${rod.toY.toInt()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _shortLabels[value.toInt()],
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _maxY / 4,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: AppColors.surfaceLight,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _barGroups,
            ),
          ),
        ),
      ],
    );
  }

  List<String> get _labels => ['Wins', 'Games', 'Legs', 'High Finish', 'Avg'];
  List<String> get _shortLabels => ['W', 'G', 'L', 'HF', 'Avg'];

  List<double> get _values => [
        stats.totalWins.toDouble(),
        stats.totalGames.toDouble(),
        stats.totalLegsWon.toDouble(),
        stats.highestFinish.toDouble(),
        stats.averageScore,
      ];

  double get _maxY {
    final max = _values.reduce((a, b) => a > b ? a : b);
    return max < 10 ? 10 : max * 1.2;
  }

  List<BarChartGroupData> get _barGroups {
    const colors = [
      AppColors.primaryRed,
      AppColors.primaryRedLight,
      AppColors.secondaryYellow,
      AppColors.secondaryYellowDark,
      AppColors.success,
    ];

    return List.generate(_values.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: _values[index],
            color: colors[index],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    });
  }
}

/// Pie chart showing win rate.
class WinRateChart extends StatelessWidget {
  final PlayerStats stats;

  const WinRateChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.totalGames == 0) {
      return const SizedBox.shrink();
    }

    final winRate = stats.totalGames > 0
        ? (stats.totalWins / stats.totalGames * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Win Rate',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: [
                      PieChartSectionData(
                        value: stats.totalWins.toDouble(),
                        color: AppColors.secondaryYellow,
                        title: '${winRate.toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        radius: 40,
                      ),
                      PieChartSectionData(
                        value: (stats.totalGames - stats.totalWins).toDouble(),
                        color: AppColors.surfaceLight,
                        title: '',
                        radius: 35,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(
                    color: AppColors.secondaryYellow,
                    label: 'Wins (${stats.totalWins})',
                  ),
                  const SizedBox(height: 8),
                  _LegendItem(
                    color: AppColors.surfaceLight,
                    label: 'Losses (${stats.totalGames - stats.totalWins})',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
