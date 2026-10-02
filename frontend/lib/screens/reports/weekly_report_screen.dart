import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HealthProvider>(context, listen: false).fetchWeeklyReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final health = Provider.of<HealthProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final report = health.weeklyReport;
    final weeklyData = report?['weeklyData'] as List<dynamic>? ?? [];
    final summary = report?['summary'] as Map<String, dynamic>? ?? {};

    final totalSteps = summary['totalSteps'] ?? 0;
    final avgSteps = summary['avgSteps'] ?? 0;
    final avgSleep = summary['avgSleep'] ?? 0.0;
    final totalWorkouts = summary['totalWorkouts'] ?? 0;
    final healthScore = summary['healthScore'] ?? 85;

    // Dynamic maxY to prevent bars from drawing outside chart bounds
    final maxSteps = weeklyData.fold<double>(10000.0, (m, e) {
      final s = (e['steps'] as num?)?.toDouble() ?? 0.0;
      return s > m ? s : m;
    });
    final stepsMaxY = (maxSteps * 1.15).ceilToDouble();

    final maxCals = weeklyData.fold<double>(2500.0, (m, e) {
      final inVal = (e['caloriesConsumed'] as num?)?.toDouble() ?? 0.0;
      final outVal = (e['caloriesBurned'] as num?)?.toDouble() ?? 0.0;
      final localMax = inVal > outVal ? inVal : outVal;
      return localMax > m ? localMax : m;
    });
    final calsMaxY = (maxCals * 1.15).ceilToDouble();

    final maxSleep = weeklyData.fold<double>(8.0, (m, e) {
      final sl = (e['sleepHours'] as num?)?.toDouble() ?? 0.0;
      return sl > m ? sl : m;
    });
    final sleepMaxY = (maxSleep * 1.2).clamp(10.0, 24.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Weekly Performance Analytics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: health.isLoadingReport
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => health.fetchWeeklyReport(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekly Health Score Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.orangeGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33FF6B00),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Circular Health Score
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 10),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$healthScore',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),

                            // Health Score Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overall Health Score',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    healthScore >= 80
                                        ? 'Superb performance! Consistent steps and workout volume this week.'
                                        : 'Good progress! Push sleep and steps a bit higher to maximize recovery.',
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4 Summary Metric Tiles
                      Row(
                        children: [
                          Expanded(
                            child: _summaryTile(
                              'Weekly Steps',
                              totalSteps.toString(),
                              'Avg $avgSteps/day',
                              Icons.directions_walk_rounded,
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryTile(
                              'Sleep Avg',
                              '${avgSleep}h',
                              'Goal: ${auth.dailySleepGoal}h',
                              Icons.bedtime_rounded,
                              AppColors.sleepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryTile(
                              'Workouts Done',
                              totalWorkouts.toString(),
                              'Workouts',
                              Icons.fitness_center_rounded,
                              AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryTile(
                              'Avg Intake',
                              '${summary['avgCaloriesConsumed'] ?? 0} kcal',
                              'Burned: ${summary['avgCaloriesBurned'] ?? 0} kcal',
                              Icons.local_fire_department_rounded,
                              AppColors.caloriesRed,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 1. Graph: Daily Steps (fl_chart BarChart)
                      _chartContainer(
                        title: 'Daily Steps',
                        chart: SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: stepsMaxY,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 != 0) return const SizedBox.shrink();
                                      final i = value.toInt();
                                      if (i >= 0 && i < weeklyData.length) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: Text(
                                            weeklyData[i]['day'] ?? '',
                                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: weeklyData.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final val = (entry.value['steps'] as num?)?.toDouble() ?? 0.0;
                                return BarChartGroupData(
                                  x: idx,
                                  barRods: [
                                    BarChartRodData(
                                      toY: val > 0 ? val : 500,
                                      color: val >= auth.dailyStepGoal ? AppColors.success : AppColors.primary,
                                      width: 14,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 2. Graph: Calories In vs Calories Out (fl_chart Dual BarChart)
                      _chartContainer(
                        title: 'Food Intake vs Calories Burned',
                        subtitle: 'Orange = Consumed (Food) • Red = Burned (Exercise)',
                        chart: SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: calsMaxY,
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 != 0) return const SizedBox.shrink();
                                      final i = value.toInt();
                                      if (i >= 0 && i < weeklyData.length) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: Text(
                                            weeklyData[i]['day'] ?? '',
                                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: weeklyData.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final inVal = (entry.value['caloriesConsumed'] as num?)?.toDouble() ?? 0.0;
                                final outVal = (entry.value['caloriesBurned'] as num?)?.toDouble() ?? 0.0;

                                return BarChartGroupData(
                                  x: idx,
                                  barRods: [
                                    BarChartRodData(toY: inVal, color: AppColors.primary, width: 7, borderRadius: BorderRadius.circular(4)),
                                    BarChartRodData(toY: outVal, color: AppColors.caloriesRed, width: 7, borderRadius: BorderRadius.circular(4)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Graph: Sleep Hours Trend (fl_chart LineChart)
                      _chartContainer(
                        title: 'Night Sleep & Rest (Hours)',
                        subtitle: 'Estimated night sleep',
                        chart: SizedBox(
                          height: 160,
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: sleepMaxY,
                              minX: 0,
                              maxX: (weeklyData.isEmpty ? 6 : weeklyData.length - 1).toDouble(),
                              clipData: const FlClipData.all(),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 != 0) return const SizedBox.shrink();
                                      final i = value.toInt();
                                      if (i >= 0 && i < weeklyData.length) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: Text(
                                            weeklyData[i]['day'] ?? '',
                                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: weeklyData.asMap().entries.map((e) {
                                    final val = (e.value['sleepHours'] as num?)?.toDouble() ?? 7.0;
                                    return FlSpot(e.key.toDouble(), val > 0 ? val : 7.0);
                                  }).toList(),
                                  isCurved: true,
                                  color: AppColors.sleepPurple,
                                  barWidth: 3,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.sleepPurple.withValues(alpha: 0.15),
                                  ),
                                  dotData: const FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _summaryTile(String label, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _chartContainer({
    required String title,
    String? subtitle,
    required Widget chart,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08FF6B00),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}
