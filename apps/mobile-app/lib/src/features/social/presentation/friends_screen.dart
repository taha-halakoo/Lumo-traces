import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/widgets/liquid_background.dart';
import '../data/social_repository.dart';

final friendsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(socialRepositoryProvider).getFriends();
});

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Connections", style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () {}, 
          ),
        ],
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          friendsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
            data: (friends) {
              if (friends.isEmpty) {
                return const Center(child: Text("No connections yet", style: TextStyle(color: Colors.white54)));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final username = friend['username'] ?? 'Unknown';
                  final avatar = friend['avatar_url'] ?? "https://i.pravatar.cc/150";

                  return GlassPanel(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    backgroundColor: Colors.white.withOpacity(0.05),
                    radius: 16,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(avatar),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Connected",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white38),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 30).ms).slideX();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
