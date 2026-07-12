import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _farmController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cacheService = ref.read(cacheServiceProvider);
    _ipController.text = cacheService.getBackendIP();
    
    final profile = ref.read(userProfileProvider);
    _nameController.text = profile.userName;
    _farmController.text = profile.farmName;
    _locationController.text = profile.location;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _nameController.dispose();
    _farmController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final cacheService = ref.read(cacheServiceProvider);
    await cacheService.saveBackendIP(_ipController.text.trim());
    
    final notifier = ref.read(userProfileProvider.notifier);
    await notifier.updateProfile(
      userName: _nameController.text.trim(),
      farmName: _farmController.text.trim(),
      location: _locationController.text.trim(),
    );
    
    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.settingsProfile, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.loginHintName.replaceAll(' (e.g. John Doe)', ''),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _farmController,
                  decoration: InputDecoration(
                    labelText: loc.loginHintFarm.replaceAll(' (e.g. Green Valley Farm)', ''),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.landscape),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: loc.settingsLocation,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 24),
                Text(loc.settingsLanguage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: currentLocale,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.language),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
                    DropdownMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)')),
                    DropdownMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(localeProvider.notifier).setLocale(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.settingsConnection, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: loc.backendIP,
                    hintText: "http://127.0.0.1:8000",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loc.btnSave, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
