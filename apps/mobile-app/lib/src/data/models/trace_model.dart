import 'package:latlong2/latlong.dart';

enum TraceType { standard, story, challenge, orb, friend }

class Trace {
  final String id;
  final String authorId;
  final LatLng location;
  final TraceType type;
  final String? contentText;
  final String? mediaUrl;
  final List<String> hashtags;
  final String? musicTrackId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  
  // New Fields from Hybrid Search
  final String? authorUsername;
  final bool isFriend;
  final double score;

  Trace({
    required this.id,
    required this.authorId,
    required this.location,
    required this.type,
    this.contentText,
    this.mediaUrl,
    this.hashtags = const [],
    this.musicTrackId,
    required this.createdAt,
    this.expiresAt,
    this.authorUsername,
    this.isFriend = false,
    this.score = 0.0,
  });

  factory Trace.fromJson(Map<String, dynamic> json) {
    return Trace(
      id: json['id'],
      authorId: json['author_id'],
      location: LatLng(json['lat'], json['long']),
      type: TraceType.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['type'] as String).toUpperCase(),
        orElse: () => TraceType.standard,
      ),
      contentText: json['content_text'],
      mediaUrl: json['media_url'],
      hashtags: (json['hashtags'] as List<dynamic>?)?.cast<String>() ?? [],
      musicTrackId: json['music_track_id'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      
      // New Fields Mapping
      authorUsername: json['author_username'],
      isFriend: json['is_friend'] ?? false,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}