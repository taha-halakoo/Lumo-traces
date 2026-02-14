import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/widgets/liquid_background.dart';
import '../../map/data/trace_repository.dart';

final myTracesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(traceRepositoryProvider).getMyTraces();
});

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myTracesAsync = ref.watch(myTracesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Collections", style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          myTracesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
            data: (traces) {
              if (traces.isEmpty) return const Center(child: Text("No traces collected", style: TextStyle(color: Colors.white54)));

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: 1, // Just "My Traces" folder for now
                itemBuilder: (context, index) {
                  return GlassPanel(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Area
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: const Center(
                              child: Icon(Icons.folder_open, color: Colors.white24, size: 48),
                            ),
                          ),
                        ),
                        // Text Area
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "My Traces",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${traces.length} Traces",
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 100).ms).scale();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
