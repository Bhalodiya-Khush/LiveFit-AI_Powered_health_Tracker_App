import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../widgets/exercise_gif_dialog.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final health = Provider.of<HealthProvider>(context);

    final exercises = health.suggestedExercises;
    final weather = health.weather;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'AI Suggested Workouts',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => health.fetchExercises(),
            tooltip: 'Regenerate Exercises',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => health.fetchExercises(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact AI & Weather Rationale Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeCoralGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x28FF5722),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tailored For You Today',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${weather?['condition'] ?? 'Pleasant'} • ${weather?['temperature'] ?? 24}°C • ${auth.age}y athlete',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Today\'s Routine',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (health.isLoadingExercises)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (exercises.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.fitness_center_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Generating exercises...',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ...exercises.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final ex = entry.value;
                    final isDone = ex['completed'] == true;
                    final gifUrl = getWorkingExerciseGif(ex['gifUrl'], ex['exerciseName']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDone ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
                          width: isDone ? 1.5 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            // Tapping opens the comprehensive Exercise Widget
                            showDialog(
                              context: context,
                              builder: (_) => ExerciseGifDialog(
                                exercise: ex,
                                onMarkDone: () => _markDone(context, health, ex['_id']),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                // 1. Demo GIF thumbnail with index badge & play overlay
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: 68,
                                        height: 68,
                                        color: const Color(0xFF1E293B),
                                        child: Image.network(
                                          gifUrl,
                                          width: 68,
                                          height: 68,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color: AppColors.primaryPeach,
                                            child: const Icon(
                                              Icons.fitness_center_rounded,
                                              color: AppColors.primary,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Number index or completed checkmark badge
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isDone ? AppColors.success : AppColors.primaryDark,
                                          shape: BoxShape.circle,
                                        ),
                                        child: isDone
                                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                                            : Text(
                                                '$index',
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    // Play icon overlay hint
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 14),

                                // 2. Exercise Name
                                Expanded(
                                  child: Text(
                                    ex['exerciseName'] ?? '',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // 3. Mark as Done Button (Checkmark Icon Only)
                                isDone
                                    ? Container(
                                        width: 38,
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.success.withValues(alpha: 0.5),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: AppColors.success,
                                          size: 20,
                                        ),
                                      )
                                    : InkWell(
                                        borderRadius: BorderRadius.circular(19),
                                        onTap: () => _markDone(context, health, ex['_id']),
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryPeach,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.primary.withValues(alpha: 0.4),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markDone(BuildContext context, HealthProvider health, String id) async {
    final burned = await health.completeExercise(id);
    if (burned != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔥 Great job! Burned $burned calories!'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
