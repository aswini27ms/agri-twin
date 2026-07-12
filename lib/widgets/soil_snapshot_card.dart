import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/soil_provider.dart';
import 'package:agri_edge_ai/l10n/app_localizations.dart';

class SoilSnapshotCard extends ConsumerWidget {
  const SoilSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soilState = ref.watch(soilProvider);
    final localizations = AppLocalizations.of(context);

    if (soilState.isLoading && soilState.data == null) {
      return const Card(
        color: Color(0xFFFAFAF7),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
        ),
      );
    }

    final data = soilState.data;
    if (data == null) {
      return Card(
        color: const Color(0xFFFAFAF7),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF9A825), size: 48),
              const SizedBox(height: 8),
              Text(
                localizations?.connectionFailed ?? 'No soil data available',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final timeString = DateFormat('hh:mm:ss a').format(data.timestamp);

    return Card(
      color: const Color(0xFFFAFAF7),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations?.soilSnapshot ?? "Soil Snapshot",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  localizations?.lastUpdated(timeString) ??
                      "Last updated: $timeString",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildSoilMetricCard(
                  title: localizations?.nitrogen ?? "Nitrogen",
                  value: "${data.nitrogen.toStringAsFixed(1)} ppm",
                  numericValue: data.nitrogen,
                  status: _getNitrogenStatus(data.nitrogen),
                  baseColor: const Color(0xFF2E7D32),
                  icon: Icons.science_outlined,
                ),
                _buildSoilMetricCard(
                  title: localizations?.phosphorus ?? "Phosphorus",
                  value: "${data.phosphorus.toStringAsFixed(1)} ppm",
                  numericValue: data.phosphorus,
                  status: _getPhosphorusStatus(data.phosphorus),
                  baseColor: const Color(0xFFE65100),
                  icon: Icons.grass_outlined,
                ),
                _buildSoilMetricCard(
                  title: localizations?.potassium ?? "Potassium",
                  value: "${data.potassium.toStringAsFixed(1)} ppm",
                  numericValue: data.potassium,
                  status: _getPotassiumStatus(data.potassium),
                  baseColor: const Color(0xFF00838F),
                  icon: Icons.grain_outlined,
                ),
                _buildSoilMetricCard(
                  title: localizations?.moisture ?? "Moisture",
                  value: "${data.moisture.toStringAsFixed(1)}%",
                  numericValue: data.moisture,
                  status: _getMoistureStatus(data.moisture),
                  baseColor: _getMoistureTextColor(data.moisture),
                  icon: Icons.opacity_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilMetricCard({
    required String title,
    required String value,
    required double numericValue,
    required String status,
    required Color baseColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: baseColor.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: baseColor, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: baseColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (numericValue / 100.0).clamp(0.0, 1.0),
              backgroundColor: baseColor.withOpacity(0.08),
              color: baseColor,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  String _getNitrogenStatus(double n) {
    if (n < 30) return "LOW - Needs Urea";
    if (n > 60) return "HIGH - Stop Fertilizer";
    return "HEALTHY";
  }

  String _getPhosphorusStatus(double p) {
    if (p < 25) return "LOW - Needs DAP";
    if (p > 50) return "HIGH - Stable";
    return "HEALTHY";
  }

  String _getPotassiumStatus(double k) {
    if (k < 40) return "LOW - Needs Potash";
    if (k > 80) return "HIGH - Stable";
    return "HEALTHY";
  }

  String _getMoistureStatus(double m) {
    if (m < 20) return "CRITICAL - Irrigate";
    if (m < 35) return "LOW - Water Soon";
    if (m > 70) return "SURPLUS - Wet";
    return "OPTIMAL";
  }

  Color _getMoistureTextColor(double m) {
    if (m < 20) return const Color(0xFFC62828);
    if (m < 35) return const Color(0xFFF57F17);
    return const Color(0xFF0277BD);
  }
}
