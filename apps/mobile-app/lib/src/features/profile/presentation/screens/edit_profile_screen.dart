import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/widgets/liquid_background.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import '../../data/user_repository.dart';
import '../profile_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _fullNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final profile = await ref.read(userProfileProvider.future);
    _fullNameCtrl.text = profile['full_name'] ?? '';
    _bioCtrl.text = profile['bio'] ?? '';
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticService.mediumImpact();
    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).updateProfile({
        'full_name': _fullNameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      });
      ref.invalidate(userProfileProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("SAVE", style: TextStyle(color: DesignTokens.liquidBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                        image: const DecorationImage(image: NetworkImage("https://i.pravatar.cc/300"), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: CircleAvatar(
                        backgroundColor: DesignTokens.liquidBlue,
                        radius: 16,
                        child: IconButton(icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white), onPressed: () {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _fieldLabel("FULL NAME"),
              _glassTextField(_fullNameCtrl, "Your real name"),
              const SizedBox(height: 24),
              _fieldLabel("BIO"),
              _glassTextField(_bioCtrl, "Tell the world your story...", maxLines: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _glassTextField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      backgroundColor: Colors.white.withOpacity(0.05),
      radius: 12,
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
