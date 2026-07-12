import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import '../models/village_alert.dart';

class VillageDashboardScreen extends ConsumerWidget {
  const VillageDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Village Intelligence"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(alertsProvider.notifier).fetchAlerts(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(alertsProvider.notifier).fetchAlerts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummarySection(context, ref),
              const SizedBox(height: 24),
              const Text("Recent Alerts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildAlertsList(context, alertsState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(villageSummaryProvider);

    return summaryState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error loading summary: $err")),
      data: (summaryData) {
        final narrative = summaryData['narrative'] ?? "No summary available.";
        final stats = summaryData['stats'];

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text("AI Village Summary", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                narrative,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              if (stats != null) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol("Affected Farms", stats['affected_farms'].toString()),
                    _buildStatCol("High Risk Grids", stats['high_risk_count'].toString(), color: Colors.redAccent),
                  ],
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCol(String label, String value, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildAlertsList(BuildContext context, AsyncValue<List<VillageAlert>> alertsState) {
    return alertsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (alerts) {
        if (alerts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("No active alerts in the village."),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alerts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildAlertCard(context, alerts[index]);
          },
        );
      },
    );
  }

  Widget _buildAlertCard(BuildContext context, VillageAlert alert) {
    Color riskColor = alert.riskLevel.toLowerCase() == 'high' ? Colors.redAccent 
        : (alert.riskLevel.toLowerCase() == 'moderate' ? Colors.orangeAccent : Colors.yellow);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Farm: ${alert.farmName}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: riskColor),
                ),
                child: Text(
                  alert.riskLevel.toUpperCase(),
                  style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Detected: ${alert.disease} on ${alert.crop}", style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text("Grid: ${alert.gridId}", style: const TextStyle(color: Colors.grey)),
              const Spacer(),
              Text("Severity: ${(alert.severity).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}
