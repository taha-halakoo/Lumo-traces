export type TraceType = 'STANDARD' | 'STORY' | 'CHALLENGE' | 'ORB' | 'FRIEND';

export interface Trace {
  id: string;
  author_id: string;
  lat: number;
  long: number;
  type: TraceType;
  content_text?: string;
  media_url?: string;
  hashtags?: string[];
  music_track_id?: string;
  created_at: string;
  expires_at?: string; 
  unlocked_by?: string[];
}

export interface UserProfile {
  id: string;
  username: string;
  avatar_url?: string;
  interests_tags?: string[]; 
}

export interface NearbyParams {
  lat: number;
  long: number;
  radius: number;
  user_mood_vector?: number[]; 
}

export interface TraceBody {
    lat: number;
    long: number;
    text?: string;
    type?: TraceType;
    visibility?: 'public' | 'private' | 'friends';
    contentUrl?: string; // Legacy support or media
    tags?: string[];
}

export interface NearbyQuery {
    lat: string | number; // Query params often come as strings
    long: string | number;
    radius?: string | number;
    searchText?: string;
}
