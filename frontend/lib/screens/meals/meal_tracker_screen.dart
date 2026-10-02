import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/health_provider.dart';

class MealTrackerScreen extends StatefulWidget {
  const MealTrackerScreen({super.key});

  @override
  State<MealTrackerScreen> createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends State<MealTrackerScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedMealType = 'lunch';
  bool _isAnalyzing = false;
  bool _userManuallyChanged = false;

  final List<String> _mealTypes = ['breakfast', 'lunch', 'snack', 'dinner'];

  String _getTimeBasedMealType() {
    final now = DateTime.now();
    final decimalTime = now.hour + (now.minute / 60.0);
    if (decimalTime >= 5.0 && decimalTime < 11.5) {
      return 'breakfast';
    } else if (decimalTime >= 11.5 && decimalTime < 16.0) {
      return 'lunch';
    } else if (decimalTime >= 16.0 && decimalTime < 19.0) {
      return 'snack';
    } else {
      return 'dinner';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedMealType = _getTimeBasedMealType();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final health = Provider.of<HealthProvider>(context, listen: false);
      if (health.currentMealType.isNotEmpty && !_userManuallyChanged) {
        setState(() {
          _selectedMealType = health.currentMealType;
        });
      }
      health.fetchTodayMeals().then((_) {
        if (mounted && !_userManuallyChanged && health.currentMealType.isNotEmpty) {
          setState(() {
            _selectedMealType = health.currentMealType;
          });
        }
      });
    });
  }

  Future<void> _captureMealPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo == null) return;

      setState(() => _isAnalyzing = true);

      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (!mounted) return;
      final health = Provider.of<HealthProvider>(context, listen: false);

      final result = await health.logMealPhoto(
        base64Image: base64Image,
        mealType: _selectedMealType,
      );

      setState(() => _isAnalyzing = false);

      if (mounted) {
        _showMealAnalysisResultDialog(result['meal']);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal analysis error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showMealAnalysisResultDialog(Map<String, dynamic> meal) {
    final items = meal['items'] as List<dynamic>? ?? [];
    final totalCalories = meal['totalCalories'] ?? 0;
    final totalProtein = meal['totalProtein'] ?? 0;
    final totalCarbs = meal['totalCarbs'] ?? 0;
    final totalFat = meal['totalFat'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              const SizedBox(width: 10),
              Text(
                'AI Meal Analysis',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Vision detected nutritional analysis:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  // Nutrition Ring / Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$totalCalories kcal',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _macroItem('Protein', '${totalProtein}g'),
                            _macroItem('Carbs', '${totalCarbs}g'),
                            _macroItem('Fat', '${totalFat}g'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Identified Foods & Portions',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),

                  ...items.map((it) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it['name'] ?? '',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${it['quantity']} (${it['estimatedGrams']}g)',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${it['calories']} kcal',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Verified',
                                    style: GoogleFonts.inter(fontSize: 9, color: AppColors.info, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Saved to Today\'s Calories'),
            ),
          ],
        );
      },
    );
  }

  Widget _macroItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final health = Provider.of<HealthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Meal & Nutrition Tracker',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gemini + OpenFoodFacts AI Vision Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FF6B00),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Smart Meal Scanner',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Smart AI Recognition Engine',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Snap a photo of your plate. AI detects food items and portions, estimates nutrition, and auto-logs calories to your dashboard!',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Meal Type Selector Segmented Control
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: _mealTypes.map((type) {
                          final isSel = _selectedMealType == type;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMealType = type;
                                  _userManuallyChanged = true;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSel ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: isSel
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x28000000),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      type[0].toUpperCase() + type.substring(1),
                                      style: GoogleFonts.outfit(
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                        color: isSel ? AppColors.primaryDark : Colors.white,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Camera & Gallery Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing ? null : () => _captureMealPhoto(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                            label: Text(
                              _isAnalyzing ? 'Analyzing...' : 'Take Photo',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isAnalyzing ? null : () => _captureMealPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                            label: Text(
                              'Gallery',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white70),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Today's Macro Totals Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Calories Consumed',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${health.caloriesConsumed} kcal',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _dailyMacroTile('Protein', '${health.mealTotals['protein'] ?? 0}g', AppColors.primary),
                        _dailyMacroTile('Carbs', '${health.mealTotals['carbs'] ?? 0}g', AppColors.warning),
                        _dailyMacroTile('Fat', '${health.mealTotals['fat'] ?? 0}g', AppColors.caloriesRed),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Today's Meals Timeline
              Text(
                'Today\'s Meals',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              if (health.todayMeals.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.flatware_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        'No meals logged yet today',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Snap your breakfast, lunch, or dinner above!',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...health.todayMeals.map((meal) {
                  final mealType = (meal['mealType'] ?? 'meal').toString();
                  final calories = meal['totalCalories'] ?? 0;
                  final items = meal['items'] as List<dynamic>? ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPeach,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                mealType.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            Text(
                              '$calories kcal',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: items.map((it) {
                            return Chip(
                              label: Text(
                                '${it['name']} (${it['quantity']})',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary),
                              ),
                              backgroundColor: AppColors.background,
                              side: const BorderSide(color: AppColors.borderLight),
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dailyMacroTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
