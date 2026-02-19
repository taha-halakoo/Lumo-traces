import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/widgets/liquid_background.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import '../data/user_repository.dart';

final publicProfileProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.read(userRepositoryProvider).getProfile(id);
});

final publicTracesProvider = FutureProvider.family<List<dynamic>, String>((ref, id) async {
  return ref.read(userRepositoryProvider).getUserTraces(id);
});

final isFollowingProvider = FutureProvider.family<bool, String>((ref, id) async {
  return ref.read(userRepositoryProvider).getFollowStatus(id);
});

class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  Future<void> _handleFollow(WidgetRef ref, bool isFollowing) async {
    HapticService.selectionClick();
    if (isFollowing) {
      await ref.read(userRepositoryProvider).unfollow(userId);
    } else {
      await ref.read(userRepositoryProvider).follow(userId);
    }
    ref.invalidate(isFollowingProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final tracesAsync = ref.watch(publicTracesProvider(userId));
    final followingAsync = ref.watch(isFollowingProvider(userId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error loading user: $err")),
            data: (profile) {
              final stats = profile['stats'] ?? {};
              final username = profile['username'] ?? 'Explorer';
              final avatarUrl = profile['avatar_url'] ?? "https://api.dicebear.com/7.x/bottts/svg?seed=$username";

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 100),
                        Hero(
                          tag: 'user_avatar_$userId',
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: DesignTokens.liquidBlue.withOpacity(0.5), width: 3),
                              boxShadow: [BoxShadow(color: DesignTokens.liquidBlue.withOpacity(0.3), blurRadius: 40)],
                              image: DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover),
                            ),
                          ),
                        ).animate().scale(curve: Curves.elasticOut),
                        const SizedBox(height: 20),
                        Text(profile['full_name'] ?? username, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("@$username", style: const TextStyle(color: Colors.white54)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            followingAsync.when(
                              data: (isFollowing) => _buildActionBtn(
                                context, 
                                isFollowing ? "Unfollow" : "Follow", 
                                isFollowing ? Icons.person_remove : Icons.person_add, 
                                !isFollowing,
                                onTap: () => _handleFollow(ref, isFollowing),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const SizedBox(),
                            ),
                            const SizedBox(width: 12),
                            _buildActionBtn(context, "Message", Icons.chat_bubble_outline, false, onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GlassPanel(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Colors.white.withOpacity(0.03),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _stat("Traces", "${stats['dropped_count'] ?? 0}"),
                                _stat("REP", "${profile['reputation_points'] ?? 0}"),
                                _stat("Level", "${stats['level'] ?? 1}"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
                      child: Text("RECENT TRACES", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                  ),
                  tracesAsync.when(
                    loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                    error: (err, _) => SliverToBoxAdapter(child: Center(child: Text("Error: $err"))),
                    data: (traces) {
                      if (traces.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No public memories", style: TextStyle(color: Colors.white24)))));
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final trace = traces[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                              child: GestureDetector(
                                onTap: () {
                                  HapticService.selectionClick();
                                  context.push('/trace/${trace['id']}');
                                },
                                child: GlassPanel(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor: Colors.white.withOpacity(0.05),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, color: DesignTokens.liquidBlue.withOpacity(0.5), size: 18),
                                      const SizedBox(width: 16),
                                      Expanded(child: Text(trace['content_text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13))),
                                      Text("2d ago", style: TextStyle(color: Colors.white24, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1);
                          },
                          childCount: traces.length,
                        ),
                      );
                    }
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, String label, IconData icon, bool primary, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: primary ? DesignTokens.liquidBlue.withOpacity(0.8) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary ? Colors.white24 : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
