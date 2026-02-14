import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import '../../map/presentation/map_providers.dart';
import '../../map/data/trace_repository.dart';

class CreateTraceScreen extends ConsumerStatefulWidget {
  const CreateTraceScreen({super.key});

  @override
  ConsumerState<CreateTraceScreen> createState() => _CreateTraceScreenState();
}

class _CreateTraceScreenState extends ConsumerState<CreateTraceScreen> {
  String _selectedType = 'STANDARD';
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _types = ['STANDARD', 'STORY', 'CHALLENGE', 'ORB', 'FRIEND'];

  Future<void> _submit() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final locationAsync = ref.read(userLocationProvider);
      
      final position = await ref.read(userLocationProvider.future);

      await ref.read(traceRepositoryProvider).createTrace({
        'lat': position.latitude,
        'long': position.longitude,
        'text': text,
        'type': _selectedType,
        'visibility': 'public', // Default
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trace dropped!")));
        ref.invalidate(nearbyTracesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to drop trace: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: DesignTokens.glassDarkBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("New Trace", style: theme.textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text("DROP", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Type Selector (Pills)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: GlassPanel(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      radius: 24,
                      backgroundColor: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.white.withOpacity(0.1),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animate(target: isSelected ? 1 : 0).scale(end: const Offset(1.1, 1.1), duration: 200.ms).shimmer(duration: 800.ms),
                  );
                }).toList(),
              ),
            ).animate().slideX(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOut),
            
            const SizedBox(height: 24),

            // 2. Content Input (Glass Area)
            Expanded(
              child: GlassPanel(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.05),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: "What memory are you leaving here?",
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            
            const SizedBox(height: 24),

            // 3. Location Indicator
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                const Text("Current Location (±5m)", style: TextStyle(color: Colors.white70)),
              ],
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
