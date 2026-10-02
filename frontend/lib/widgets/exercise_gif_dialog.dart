import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';

String getWorkingExerciseGif(dynamic rawUrl, String? name) {
  final url = rawUrl?.toString() ?? '';
  // If backend provided a working GIF link from our database, use it directly
  if (url.isNotEmpty && !url.contains('static.exercisedb.dev') && url.startsWith('http')) {
    return url;
  }
  final n = (name ?? '').toLowerCase();
  if (n.contains('push-up') || n.contains('pushup')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/I4hDWkc.gif';
  }
  if (n.contains('squat') || n.contains('wall sit')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/LIlE5Tn.gif';
  }
  if (n.contains('jack') || n.contains('star jump')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/1g5bPpA.gif';
  }
  if (n.contains('plank')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/CosupLu.gif';
  }
  if (n.contains('lunge')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/kMzUs9Y.gif';
  }
  if (n.contains('mountain') || n.contains('climber')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/RJgzwny.gif';
  }
  if (n.contains('bridge')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/u0cNiij.gif';
  }
  if (n.contains('high knee') || n.contains('marching')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/ealLwvX.gif';
  }
  if (n.contains('walk') || n.contains('step-up') || n.contains('step up')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/IZVHb27.gif';
  }
  if (n.contains('yoga') || n.contains('stretch') || n.contains('dog') || n.contains('mobility') || n.contains('arm circle')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/bWlZvXh.gif';
  }
  if (n.contains('crunch') || n.contains('abs') || n.contains('twist')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/31xL9wV.gif';
  }
  if (n.contains('dip') || n.contains('tricep')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/XjA0wB3.gif';
  }
  if (n.contains('calf') || n.contains('heel lift')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/yY2w2Z3.gif';
  }
  if (n.contains('bird dog') || n.contains('dead bug') || n.contains('superman')) {
    return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/rmEukuS.gif';
  }
  return 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/LIlE5Tn.gif';
}

class ExerciseGifDialog extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback? onMarkDone;

  const ExerciseGifDialog({
    super.key,
    required this.exercise,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final name = exercise['exerciseName'] ?? 'Exercise';
    final gifUrl = getWorkingExerciseGif(exercise['gifUrl'], name);
    final target = exercise['targetMuscle'] ?? 'Full Body';
    final met = (exercise['metValue'] as num?)?.toDouble() ?? 5.0;
    final duration = exercise['durationMinutes'] ?? 15;
    final calories = exercise['caloriesBurned'] ?? ((met * 70 * (duration / 60)).round());
    final reps = exercise['repetitions'] ?? '3 sets';
    final isCompleted = exercise['completed'] == true;
    final instructions = exercise['instructions'] as List<dynamic>? ?? [];

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          children: [
            // Header with Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Video/GIF Container
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              gifUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2.5,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Loading video demonstration...',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.fitness_center_rounded, size: 48, color: AppColors.primary),
                                      const SizedBox(height: 8),
                                      Text(
                                        name,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Interactive Exercise Demo',
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Metrics Badges: Duration, Calories, Muscle (Wrapped to avoid mobile overflow)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(
                          icon: Icons.timer_outlined,
                          label: '$duration min',
                          color: AppColors.info,
                          bg: const Color(0xFFEFF6FF),
                        ),
                        _buildBadge(
                          icon: Icons.local_fire_department_rounded,
                          label: '~$calories kcal',
                          color: AppColors.caloriesRed,
                          bg: const Color(0xFFFEF2F2),
                        ),
                        _buildBadge(
                          icon: Icons.accessibility_new_rounded,
                          label: target,
                          color: AppColors.success,
                          bg: const Color(0xFFECFDF5),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Routine & Reps
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.repeat_rounded, color: AppColors.primaryDark, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Target: ',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          Expanded(
                            child: Text(
                              reps,
                              style: GoogleFonts.inter(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Instructions
                    Text(
                      'Form & Instructions',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (instructions.isNotEmpty)
                      ...instructions.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    step.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                    else
                      Text(
                        exercise['reason'] ?? 'Follow steady breathing and maintain neutral spine posture.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Footer Action Button (Checkmark Icon Only)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: isCompleted
                    ? Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.check_rounded, color: AppColors.success, size: 28),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onMarkDone?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
