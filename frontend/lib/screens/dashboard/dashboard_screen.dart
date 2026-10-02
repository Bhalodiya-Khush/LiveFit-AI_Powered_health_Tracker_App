import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/exercise_gif_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToExercises;
  final VoidCallback onNavigateToMeals;

  const DashboardScreen({
    super.key,
    required this.onNavigateToExercises,
    required this.onNavigateToMeals,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final health = Provider.of<HealthProvider>(context);

    final stepGoal = auth.dailyStepGoal;
    final sleepGoal = auth.dailySleepGoal;
    final stepProgress = (health.steps / stepGoal).clamp(0.0, 1.0);
    final sleepProgress = (health.sleepHours / sleepGoal).clamp(0.0, 1.0);
    final netCalories = health.caloriesConsumed - health.caloriesBurned;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => health.initDashboard(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: User Profile Greeting
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${auth.user?['name']?.split(' ').first ?? 'Athlete'} 👋',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Welcome back!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Live Weather Card
                WeatherCard(
                  weather: health.weather,
                  onRefresh: () => health.refreshWeatherAndLocation(),
                ),

                const SizedBox(height: 18),

                // Row 1: Steps & Sleep Cards
                Row(
                  children: [
                    // Steps Card
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Steps',
                        value: health.steps.toString(),
                        goalText: '/ $stepGoal',
                        icon: Icons.directions_walk_rounded,
                        accentColor: AppColors.primary,
                        bgColor: AppColors.primaryPeach,
                        progress: stepProgress,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Sleep Card
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Sleep',
                        value: '${health.sleepHours}h',
                        goalText: '/ ${sleepGoal}h',
                        icon: Icons.bedtime_rounded,
                        accentColor: AppColors.sleepPurple,
                        bgColor: const Color(0xFFEEF2FF),
                        progress: sleepProgress,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Row 2: Calories Consumed & Calories Burned
                Row(
                  children: [
                    // Food Calories
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Food Intake',
                        value: '${health.caloriesConsumed}',
                        goalText: 'kcal',
                        icon: Icons.restaurant_rounded,
                        accentColor: AppColors.warning,
                        bgColor: const Color(0xFFFFFBEB),
                        progress: (health.caloriesConsumed / auth.dailyCalorieGoal).clamp(0.0, 1.0),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Exercise Calories Burned
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Burned',
                        value: '${health.caloriesBurned}',
                        goalText: 'kcal',
                        icon: Icons.local_fire_department_rounded,
                        accentColor: AppColors.caloriesRed,
                        bgColor: const Color(0xFFFEF2F2),
                        progress: (health.caloriesBurned / 500).clamp(0.0, 1.0),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Net Calorie Balance Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPeach,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.balance_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Calories Balance',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Intake: ${health.caloriesConsumed} • Burned: ${health.caloriesBurned}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${netCalories > 0 ? '+' : ''}$netCalories kcal',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: netCalories > 0 ? AppColors.primaryDark : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Today's 5 AI Suggested Exercises Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggested Exercises',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            auth.healthHurdles.trim().isNotEmpty &&
                                    auth.healthHurdles.trim().toLowerCase() != 'none' &&
                                    auth.healthHurdles.trim().toLowerCase() != 'null'
                                ? 'Tailored to your age, weather & ${auth.healthHurdles}'
                                : 'Tailored to your age, weather',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onNavigateToExercises,
                      child: Text(
                        'View All 5',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Suggested Exercises Preview Carousel
                if (health.isLoadingExercises)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (health.suggestedExercises.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Text('No exercises generated yet', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                  )
                else
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: health.suggestedExercises.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final ex = health.suggestedExercises[index];
                        final isDone = ex['completed'] == true;

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => ExerciseGifDialog(
                                exercise: ex,
                                onMarkDone: () async {
                                  final burned = await health.completeExercise(ex['_id']);
                                  if (burned != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('🔥 Great job! Burned $burned calories!'),
                                        backgroundColor: AppColors.primaryDark,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          child: Container(
                            width: 220,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDone ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08FF6B00),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDone ? const Color(0xFFECFDF5) : AppColors.primaryPeach,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isDone ? 'Completed' : '${ex['durationMinutes'] ?? 15} min',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDone ? AppColors.success : AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 24),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  ex['exerciseName'] ?? '',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ex['durationMinutes'] ?? 15} mins • ${ex['targetMuscle'] ?? 'Full Body'}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String goalText,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required double progress,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                goalText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }
}
