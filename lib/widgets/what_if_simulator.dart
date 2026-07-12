import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/twin_provider.dart';
import 'package:agri_edge_ai/l10n/app_localizations.dart';

class WhatIfSimulator extends ConsumerWidget {
  const WhatIfSimulator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final twinState = ref.watch(twinProvider);
    final localizations = AppLocalizations.of(context);

    final isActive = twinState.isSimulationActive;

    return Card(
      color: const Color(0xFFFAFAF7),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.whatIfSimulator ?? "What-If Simulator",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    localizations?.simulateIrrigation ??
                        "Simulate irrigation today",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                Switch(
                  value: isActive,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (val) {
                    if (val) {
                      ref
                          .read(twinProvider.notifier)
                          .simulateScenario("irrigation");
                    } else {
                      ref.read(twinProvider.notifier).clearSimulation();
                    }
                  },
                ),
              ],
            ),
            if (isActive && twinState.simulatedTwinState != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.show_chart_rounded,
                      color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations?.simulatedLabel(
                            twinState.simulatedTwinState!.healthScore
                                .toString(),
                          ) ??
                          "Projected Score: ${twinState.simulatedTwinState!.healthScore}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                twinState.simulatedTwinState!.riskProjection,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
