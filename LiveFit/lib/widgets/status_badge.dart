import 'package:flutter/material.dart';

enum FeatureStatus { live, remaining }

class StatusBadge extends StatelessWidget {
  final String label;
  final FeatureStatus status;
  final String? featureName;
  final String? description;

  const StatusBadge({
    super.key,
    required this.label,
    this.status = FeatureStatus.live,
    this.featureName,
    this.description,
  });

  const StatusBadge.live({
    super.key,
    this.label = 'Live / Active',
    this.featureName,
    this.description,
  }) : status = FeatureStatus.live;

  const StatusBadge.remaining({
    super.key,
    this.label = 'Remaining / Next Phase',
    this.featureName,
    this.description,
  }) : status = FeatureStatus.remaining;

  @override
  Widget build(BuildContext context) {
    final isLive = status == FeatureStatus.live;
    final bgColor = isLive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final textColor = isLive ? const Color(0xFF15803D) : const Color(0xFFB45309);
    final borderColor = isLive ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D);
    final iconData = isLive ? Icons.check_circle_rounded : Icons.pending_actions_rounded;

    return InkWell(
      onTap: () {
        if (!isLive) {
          showRemainingFeatureDialog(
            context,
            title: featureName ?? label,
            details: description ??
                'This feature UI, fields, and interactions are designed for testing and UX validation. Cloud APIs and hardware sync will be integrated in the next sprint.',
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showRemainingFeatureDialog(
  BuildContext context, {
  required String title,
  String? details,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.construction_rounded, color: Color(0xFFD97706), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title — In Progress',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Text(
              'Feature Status: Prepared for Testing (Next Phase Integration)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            details ??
                'The UI interface and controls are fully drafted so testers can evaluate the layout, data flow, and user experience. Full backend connectivity will be hooked up in the upcoming release.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
        ),
      ],
    ),
  );
}
