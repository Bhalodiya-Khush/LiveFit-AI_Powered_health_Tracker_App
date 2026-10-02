import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _hurdlesList = [
    'none',
    'knee pain',
    'lower back stiffness',
    'shoulder strain',
    'asthma',
    'neck pain',
    'ankle sprain',
  ];

  void _showEditProfileModal(BuildContext context, AuthProvider auth) {
    final heightController = TextEditingController(text: auth.height.toString());
    final weightController = TextEditingController(text: auth.weight.toString());
    final stepGoalController = TextEditingController(text: auth.dailyStepGoal.toString());
    String currentHurdle = auth.healthHurdles;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Health Profile',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height',
                              suffixText: 'cm',
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight',
                              suffixText: 'kg',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: stepGoalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daily Step Goal',
                        suffixText: 'steps',
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Health Hurdle / Physical Condition',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _hurdlesList.map((h) {
                        final isSel = currentHurdle.toLowerCase() == h.toLowerCase();
                        final isNone = h == 'none';
                        return ChoiceChip(
                          label: Text(
                            isNone ? 'No Issues' : h.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isSel ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: isNone ? AppColors.success : AppColors.primary,
                          backgroundColor: AppColors.background,
                          onSelected: (_) => setModalState(() => currentHurdle = h),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () async {
                        await auth.updateProfile({
                          'height': double.tryParse(heightController.text) ?? auth.height,
                          'weight': double.tryParse(weightController.text) ?? auth.weight,
                          'dailyStepGoal': int.tryParse(stepGoalController.text) ?? auth.dailyStepGoal,
                          'healthHurdles': currentHurdle,
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStepGoalModal(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController(text: auth.dailyStepGoal.toString());
    final presets = [5000, 8000, 10000, 12000, 15000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Daily Step Goal',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a recommended target or enter your custom step goal.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Daily Steps',
                        suffixText: 'steps',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((p) {
                        final isSel = controller.text == p.toString();
                        return ActionChip(
                          label: Text(
                            NumberFormat('#,###').format(p),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          backgroundColor: isSel ? AppColors.primary : AppColors.background,
                          onPressed: () {
                            setModalState(() {
                              controller.text = p.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final val = int.tryParse(controller.text) ?? auth.dailyStepGoal;
                        if (val > 0) {
                          await auth.updateProfile({'dailyStepGoal': val});
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Daily step goal updated to ${NumberFormat('#,###').format(val)} steps!')),
                          );
                        }
                      },
                      child: const Text('Save Step Goal'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHurdleModal(BuildContext context, AuthProvider auth) {
    String currentHurdle = auth.healthHurdles;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Manage Health Hurdle',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select an active condition or tap "No Issues / Remove" to clear hurdles. LiveFit AI workouts adapt safely.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _hurdlesList.map((h) {
                        final isSel = currentHurdle.toLowerCase() == h.toLowerCase();
                        final isNone = h == 'none';
                        return ChoiceChip(
                          avatar: isNone
                              ? Icon(Icons.check_circle_outline, size: 16, color: isSel ? Colors.white : AppColors.success)
                              : null,
                          label: Text(
                            isNone ? 'No Issues / Remove Hurdle' : h.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isSel ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: isNone ? AppColors.success : AppColors.primary,
                          backgroundColor: AppColors.background,
                          onSelected: (_) => setModalState(() => currentHurdle = h),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await auth.updateProfile({'healthHurdles': currentHurdle});
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                currentHurdle == 'none'
                                    ? 'Health hurdle removed!'
                                    : 'Health hurdle updated to ${currentHurdle.toUpperCase()}',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Save Health Hurdle'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    final birthDateStr = user?['birthDate'] != null
        ? DateFormat('dd MMMM yyyy').format(DateTime.parse(user!['birthDate']))
        : 'Not set';

    // BMI calculation
    final heightMeters = auth.height / 100;
    final bmi = (auth.weight / (heightMeters * heightMeters));
    final bmiRounded = (bmi * 10).round() / 10;

    String bmiCategory = 'Normal';
    Color bmiColor = AppColors.success;
    if (bmi < 18.5) {
      bmiCategory = 'Underweight';
      bmiColor = AppColors.warning;
    } else if (bmi >= 25 && bmi < 30) {
      bmiCategory = 'Overweight';
      bmiColor = AppColors.warning;
    } else if (bmi >= 30) {
      bmiCategory = 'Obese';
      bmiColor = AppColors.error;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'User Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // User Avatar & Name Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08FF6B00),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: AppColors.orangeGradient,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33FF6B00),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (user?['name'] ?? 'U')[0].toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?['name'] ?? 'User Name',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user?['email'] ?? 'user@livefit.com',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Edit Button
                    OutlinedButton.icon(
                      onPressed: () => _showEditProfileModal(context, auth),
                      icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                      label: Text(
                        'Edit Profile',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Basic Data Card: Birthdate & Dynamically Calculated Age
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal & Age Data',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _profileInfoRow(
                      icon: Icons.cake_rounded,
                      label: 'Birthdate',
                      value: birthDateStr,
                    ),
                    const Divider(height: 24, color: AppColors.borderLight),
                    _profileInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Calculated Age',
                      value: '${auth.age} years old',
                      badge: 'Auto-calculated',
                    ),
                    const Divider(height: 24, color: AppColors.borderLight),
                    _profileInfoRow(
                      icon: Icons.wc_rounded,
                      label: 'Gender',
                      value: (user?['gender'] ?? 'male').toString().toUpperCase(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Body Metrics & Dynamic BMI Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Body Composition & BMI',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: bmiColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bmiCategory,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: bmiColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricTile('Height', '${auth.height.toInt()} cm'),
                        _metricTile('Weight', '${auth.weight.toInt()} kg'),
                        _metricTile('BMI', '$bmiRounded'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Daily Step Goal Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Daily Step Goal',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _showStepGoalModal(context, auth),
                          icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                          label: Text(
                            'Set Goal',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${NumberFormat('#,###').format(auth.dailyStepGoal)} steps',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Target for daily activity tracking',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () => _showStepGoalModal(context, auth),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: Text(
                            'Change',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Health Hurdle / Condition Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Health Hurdle',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showHurdleModal(context, auth),
                          icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                          label: Text(
                            auth.healthHurdles.toLowerCase() == 'none' ? 'Set Hurdle' : 'Change',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: auth.healthHurdles.toLowerCase() == 'none'
                            ? const Color(0xFFF0FDF4)
                            : AppColors.primaryPeach,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: auth.healthHurdles.toLowerCase() == 'none'
                              ? const Color(0xFFBBF7D0)
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                auth.healthHurdles.toLowerCase() == 'none'
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                                size: 16,
                                color: auth.healthHurdles.toLowerCase() == 'none'
                                    ? AppColors.success
                                    : AppColors.primaryDark,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  auth.healthHurdles.toLowerCase() == 'none'
                                      ? 'No physical limitations (Free form)'
                                      : 'Active: ${auth.healthHurdles.toUpperCase()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: auth.healthHurdles.toLowerCase() == 'none'
                                        ? AppColors.success
                                        : AppColors.primaryDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.healthHurdles.toLowerCase() == 'none'
                                ? 'Your daily workouts and suggestions are fully unconstrained.'
                                : 'LiveFit automatically suggests low-impact exercises safe for your condition.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (auth.healthHurdles.toLowerCase() != 'none') ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            await auth.updateProfile({'healthHurdles': 'none'});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Health hurdle removed!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                          label: Text(
                            'Remove Hurdle (No Issues)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _metricTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
