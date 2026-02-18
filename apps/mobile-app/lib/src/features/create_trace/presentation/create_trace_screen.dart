import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/features/map/presentation/map_providers.dart';
import 'package:traces_mobile/src/features/map/presentation/map_view_model.dart';
import 'package:traces_mobile/src/features/map/data/trace_repository.dart';

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
    if (text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter some text")));
        return;
    }

    setState(() => _isSubmitting = true);

    try {
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
        // Refresh the map to show the new trace
        ref.read(mapViewModelProvider.notifier).scanArea();
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
    return Scaffold(
      backgroundColor: Colors.black, // Fallback if tokens fail
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("New Trace", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _isSubmitting ? null : _submit,
              child: Center(
                child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("DROP", style: TextStyle(color: DesignTokens.neonGreen, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
           // Background Gradient
           Container(
             decoration: const BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
                 colors: [Color(0xFF0F172A), Colors.black],
               ),
             ),
           ),
           
           Padding(
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
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: GlassPanel.pill(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            backgroundColor: isSelected ? DesignTokens.liquidBlue.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: isSelected ? DesignTokens.liquidBlue : Colors.white.withOpacity(0.1),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ).animate(target: isSelected ? 1 : 0).scale(end: const Offset(1.05, 1.05), duration: 200.ms),
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
                    const Icon(Icons.location_on, color: DesignTokens.liquidBlue),
                    const SizedBox(width: 8),
                    const Text("Current Location (±5m)", style: TextStyle(color: Colors.white70)),
                  ],
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
