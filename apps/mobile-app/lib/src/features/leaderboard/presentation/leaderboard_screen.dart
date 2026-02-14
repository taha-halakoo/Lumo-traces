import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/widgets/liquid_background.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import 'package:go_router/go_router.dart';
import '../../profile/data/user_repository.dart';

final leaderboardFilterProvider = StateProvider<String>((ref) => 'GLOBAL');

final leaderboardProvider = FutureProvider<List<dynamic>>((ref) async {
  final filter = ref.watch(leaderboardFilterProvider);
  if (filter == 'GLOBAL') {
    return ref.read(userRepositoryProvider).getLeaderboard();
  } else {
    final global = await ref.read(userRepositoryProvider).getLeaderboard();
    final friends = await ref.read(userRepositoryProvider).getFriends();
    final friendIds = friends.map((f) => f['id']).toSet();
    return global.where((u) => friendIds.contains(u['id'])).toList();
  }
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final filter = ref.watch(leaderboardFilterProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Leaderboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          Column(
            children: [
              const SizedBox(height: 100),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassPanel.pill(
                  height: 45,
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: ['GLOBAL', 'CONNECTIONS'].map((f) {
                      final isSelected = filter == f;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticService.selectionClick();
                            ref.read(leaderboardFilterProvider.notifier).state = f;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? DesignTokens.liquidBlue.withOpacity(0.3) : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              f, 
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white30,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: leaderboardAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: DesignTokens.liquidBlue)),
                  error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
                  data: (users) {
                    if (users.isEmpty) return const Center(child: Text("No data available", style: TextStyle(color: Colors.white54)));
                    
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 150),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isTop3 = index < 3;
                        final rank = index + 1;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassPanel(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            backgroundColor: isTop3 
                                ? DesignTokens.liquidBlue.withOpacity(0.15 - (index * 0.03)) 
                                : Colors.white.withOpacity(0.05),
                            radius: 16,
                            border: isTop3 ? Border.all(color: DesignTokens.liquidBlue.withOpacity(0.4), width: 1.5) : null,
                            onTap: () => context.push('/profile/${user['id']}'),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 35,
                                  child: Text(
                                    "#$rank", 
                                    style: TextStyle(
                                      color: isTop3 ? DesignTokens.liquidBlue : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Hero(
                                  tag: 'user_avatar_${user['id']}',
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundImage: NetworkImage(user['avatar_url'] ?? 'https://i.pravatar.cc/150'),
                                    backgroundColor: Colors.white10,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['username'] ?? 'Anonymous',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      if (isTop3)
                                        Text(
                                          _getRankTitle(rank),
                                          style: TextStyle(color: DesignTokens.liquidBlue.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w900),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${user['reputation_points'] ?? 0}",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    const Text("REP", style: TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRankTitle(int rank) {
    if (rank == 1) return "GRANDMASTER";
    if (rank == 2) return "VISIONARY";
    if (rank == 3) return "ELITE";
    return "";
  }
}
