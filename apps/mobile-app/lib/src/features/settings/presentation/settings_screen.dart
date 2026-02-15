import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/widgets/liquid_background.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import '../../profile/data/user_repository.dart';

final userSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(userRepositoryProvider).getSettings();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/auth');
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    HapticService.lightImpact();
    await ref.read(userRepositoryProvider).updateSettings({key: value});
    ref.invalidate(userSettingsProvider);
  }

  Future<void> _resetPassword() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset email sent")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: DesignTokens.liquidBlue)),
            error: (err, _) => Center(child: Text("Error: $err")),
            data: (settings) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                children: [
                  _buildSectionHeader("NOTIFICATIONS"),
                  _buildToggleTile(
                    icon: Icons.notifications_active_outlined,
                    title: "Push Notifications",
                    value: settings['push_notifications'] ?? true,
                    onChanged: (val) => _updateSetting('push_notifications', val),
                  ),
                  _buildToggleTile(
                    icon: Icons.email_outlined,
                    title: "Email Reports",
                    value: settings['email_notifications'] ?? true,
                    onChanged: (val) => _updateSetting('email_notifications', val),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader("PRIVACY"),
                  _buildToggleTile(
                    icon: Icons.location_on_outlined,
                    title: "Location Sharing",
                    value: settings['location_sharing'] ?? true,
                    onChanged: (val) => _updateSetting('location_sharing', val),
                  ),
                  _buildToggleTile(
                    icon: Icons.visibility_off_outlined,
                    title: "Incognito Mode",
                    value: settings['incognito_mode'] ?? false,
                    onChanged: (val) => _updateSetting('incognito_mode', val),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader("SYSTEM"),
                  _buildToggleTile(
                    icon: Icons.volume_up_outlined,
                    title: "Sound Effects",
                    value: settings['sound_effects'] ?? true,
                    onChanged: (val) => _updateSetting('sound_effects', val),
                  ),
                  _buildToggleTile(
                    icon: Icons.vibration,
                    title: "Haptic Feedback",
                    value: settings['haptic_enabled'] ?? true,
                    onChanged: (val) => _updateSetting('haptic_enabled', val),
                  ),
                  _buildToggleTile(
                    icon: Icons.data_usage,
                    title: "Data Saver",
                    value: settings['data_saver'] ?? false,
                    onChanged: (val) => _updateSetting('data_saver', val),
                  ),
                  _buildSliderTile(
                    icon: Icons.radar,
                    title: "Auto-Unlock Range",
                    value: (settings['auto_unlock_range'] ?? 20).toDouble(),
                    min: 5, max: 100,
                    onChanged: (val) => _updateSetting('auto_unlock_range', val.toInt()),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader("ACCOUNT"),
                  _buildSettingsTile(
                    icon: Icons.person_outline, 
                    title: "Edit Profile", 
                    onTap: () => context.push('/edit-profile'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.security, 
                    title: "Security Details (Reset Password)", 
                    onTap: _resetPassword,
                  ),
                  
                  const SizedBox(height: 40),
                  _buildSettingsTile(
                    icon: Icons.logout, 
                    title: "Sign Out", 
                    color: DesignTokens.signalRed,
                    onTap: _logout,
                  ),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      radius: 12,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: DesignTokens.liquidBlue,
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(color: Colors.white)),
              const Spacer(),
              Text("${value.toInt()}m", style: const TextStyle(color: DesignTokens.liquidBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: min, max: max,
            activeColor: DesignTokens.liquidBlue,
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon, 
    required String title, 
    VoidCallback? onTap, 
    Color color = Colors.white,
  }) {
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      radius: 12,
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withOpacity(0.2)),
      ),
    );
  }
}
