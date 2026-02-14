import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/ui/animated_glass_button.dart';
import 'package:traces_mobile/src/core/ui/dynamic_island.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import '../../map/data/trace_repository.dart';
import '../../map/presentation/map_providers.dart';

final traceDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.read(traceRepositoryProvider).getTraceDetails(id);
});

class TraceDetailsScreen extends ConsumerStatefulWidget {
  final String traceId;

  const TraceDetailsScreen({super.key, required this.traceId});

  @override
  ConsumerState<TraceDetailsScreen> createState() => _TraceDetailsScreenState();
}

class _TraceDetailsScreenState extends ConsumerState<TraceDetailsScreen> {
  bool _isUnlocking = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() => _isUnlocking = true);
    try {
      final location = await ref.read(userLocationProvider.future);
      final result = await ref.read(traceRepositoryProvider).unlockTrace(
        widget.traceId,
        location.latitude,
        location.longitude,
      );

      if (result['success'] == true) {
        HapticService.success();
        _confettiController.play();
        
        if (mounted) {
          DynamicIslandNotification.show(
            context, 
            title: "MEMORY RETRIEVED", 
            message: "You have successfully decoded this Trace.",
            icon: Icons.lock_open,
          );
        }

        ref.invalidate(traceDetailsProvider(widget.traceId));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trace Unlocked!")));
      } else {
        HapticService.error();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Failed to unlock")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }

  Future<void> _like() async {
    try {
      await ref.read(traceRepositoryProvider).likeTrace(widget.traceId);
      ref.invalidate(traceDetailsProvider(widget.traceId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Liked!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _comment() async {
    final controller = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.glassDarkBase.withOpacity(0.9),
        title: const Text("Leave a Note", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Write something...",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Post")),
        ],
      ),
    );

    if (shouldSubmit == true && controller.text.isNotEmpty) {
      try {
        await ref.read(traceRepositoryProvider).commentTrace(widget.traceId, controller.text);
        ref.invalidate(traceDetailsProvider(widget.traceId));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comment posted!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _share(String content) {
    Share.share("Check out this Trace: \"$content\" - Found on TRACES.");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final traceAsync = ref.watch(traceDetailsProvider(widget.traceId));

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        fit: StackFit.expand,
        children: [
          GlassPanel(
            radius: 0,
            blur: DesignTokens.blurHigh,
            backgroundColor: Colors.black.withOpacity(0.6),
            child: const SizedBox.expand(),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.cyan, Colors.purple, Colors.blue, Colors.white],
            ),
          ),

          Center(
            child: traceAsync.when(
              loading: () => const CircularProgressIndicator(color: DesignTokens.liquidBlue),
              error: (err, stack) => Text("Error: $err", style: const TextStyle(color: Colors.white)),
              data: (trace) {
                final isUnlocked = trace['is_unlocked'] == true;
                return isUnlocked ? _buildContent(context, trace) : _buildLockedState(context);
              },
            ),
          ),
          
          Positioned(
            top: 50,
            right: 20,
            child: AnimatedGlassButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock, size: 80, color: Colors.white.withOpacity(0.8))
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2.seconds, color: DesignTokens.liquidBlue)
            .scaleXY(end: 1.1, duration: 1.seconds, curve: Curves.easeInOut),
        const SizedBox(height: 24),
        Text(
          "Trace Locked", 
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white, 
            fontWeight: FontWeight.bold
          )
        ),
        const SizedBox(height: 8),
        Text(
          "Get closer to unlock this memory.",
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isUnlocking ? null : () {
            HapticService.mediumImpact();
            _unlock();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.liquidBlue,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            elevation: 8,
            shadowColor: DesignTokens.liquidBlue.withOpacity(0.5),
          ),
          child: _isUnlocking 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text("Attempt Unlock"),
        ).animate(target: _isUnlocking ? 1 : 0).shimmer(duration: 1.seconds),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> trace) {
    final profile = trace['profiles'] ?? {};
    final username = profile['username'] ?? 'Anonymous';
    final avatar = profile['avatar_url'] ?? "https://api.dicebear.com/7.x/bottts/svg?seed=$username";
    final content = trace['content_text'] ?? '';
    final mediaUrl = trace['media_url'];
    final likes = trace['trace_likes'] is List ? (trace['trace_likes'] as List).length : (trace['trace_likes']?['count'] ?? 0);

    return GlassPanel(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      radius: DesignTokens.radiusLarge,
      backgroundColor: Colors.white.withOpacity(0.08), 
      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'trace_avatar_${widget.traceId}',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(avatar),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  GlassPanel.pill(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Text("Just now", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          if (mediaUrl != null)
            Hero(
              tag: 'trace_image_${widget.traceId}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(mediaUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(Icons.favorite_border, "$likes", _like),
              _actionButton(Icons.comment, "Reply", _comment),
              _actionButton(Icons.share, "Share", () => _share(content)),
            ],
          ),
          
          if (trace['trace_comments'] != null && (trace['trace_comments'] as List).isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            const Text("NOTES", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            ... (trace['trace_comments'] as List).map((comment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 12, backgroundImage: NetworkImage(comment['profiles']?['avatar_url'] ?? "https://i.pravatar.cc/100")),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment['profiles']?['username'] ?? 'Anonymous', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(comment['content'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(); 
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
