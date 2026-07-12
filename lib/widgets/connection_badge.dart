import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/soil_provider.dart';
import 'package:agri_edge_ai/l10n/app_localizations.dart';

class ConnectionBadge extends ConsumerWidget {
  const ConnectionBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(soilProvider.select((s) => s.isOnline));
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? const Color(0xFF81C784) : const Color(0xFFE57373),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline
                ? (localizations?.connected ?? 'Connected')
                : (localizations?.offline ?? 'Offline'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color:
                  isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }
}
