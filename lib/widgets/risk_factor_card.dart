import 'package:flutter/material.dart';
import 'package:agri_edge_ai/l10n/app_localizations.dart';

class RiskFactorCard extends StatelessWidget {
  final String riskText;
  final int healthScore;

  const RiskFactorCard(
      {super.key, required this.riskText, required this.healthScore});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isCritical = healthScore < 40;
    final isWarning = healthScore >= 40 && healthScore < 75;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData icon;

    if (isCritical) {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFFFCDD2);
      textColor = const Color(0xFFC62828);
      icon = Icons.error_outline_rounded;
    } else if (isWarning) {
      bgColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFECB3);
      textColor = const Color(0xFFF57F17);
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFFC8E6C9);
      textColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.topRiskFactor ?? "Top Risk Factor",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  riskText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
