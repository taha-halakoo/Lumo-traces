import { supabase } from '../lib/supabase';
import { Trace, TraceBody, NearbyQuery } from '../types/index';
import { RankingService } from './rankingService';
import { UserService } from './userService';
import { CacheService } from './cacheService';

interface HybridSearchParams {
    lat: number;
    long: number;
    radius: number;
    moodVector?: number[];
    userId: string; 
}

interface CreateTraceParams extends TraceBody {
    embedding?: number[];
}

export class TraceService {

  // --- AI Learning Loop ---
  private static async learnFromInteraction(userId: string, traceId: string, action: 'UNLOCK' | 'LIKE') {
      try {
          // 1. Get Trace Embedding
          const { data: trace } = await supabase.from('traces').select('embedding').eq('id', traceId).single();
          if (!trace || !trace.embedding) return;

          const traceVector: number[] = JSON.parse(trace.embedding as unknown as string);

          // 2. Get User Vectors
          const userVectors = await UserService.getVectors(userId);
          const currentMood = userVectors?.mood || new Array(384).fill(0);
          const currentIdentity = userVectors?.identity || new Array(384).fill(0);

          // 3. Calculate New Vectors
          // Mood updates on UNLOCK and LIKE.
          // Identity updates only on LIKE (stronger signal) or repeated UNLOCKs (simplified here to both).
          
          const newMood = RankingService.calculateNewMood(currentMood, traceVector);
          
          // Identity drift is slower, maybe only on LIKE? Let's do small drift on unlock, bigger on like.
          // For now, using standard drift from RankingService.
          const newIdentity = action === 'LIKE' 
            ? RankingService.calculateNewIdentity(currentIdentity, traceVector)
            : currentIdentity; // Only mood shifts on just unlocking/viewing? Or maybe small identity shift? 
                               // Let's stick to: Mood changes fast (context), Identity changes slow (likes).

          // 4. Save
          await UserService.updateMood(userId, newMood);
          if (action === 'LIKE') {
              await UserService.updateIdentity(userId, newIdentity);
          }

      } catch (e) {
          console.error("AI Learning Failed:", e);
          // Don't crash the request for this background task
      }
  }

  static async createTrace(userId: string, params: CreateTraceParams) {
    const { lat, long, text, type, visibility, embedding } = params;
    
    const expiresAt = type === 'STORY' ? new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() : null;

    const { data, error } = await supabase
      .from('traces')
      .insert({
        author_id: userId,
        location: `POINT(${long} ${lat})`, 
        content_text: text,
        type: type || 'STANDARD',
        visibility: visibility || 'public',
        embedding: embedding,
        expires_at: expiresAt
      })
      .select()
      .single();

    if (error) throw error;
    
    CacheService.del('feed_public');

    return data as Trace;
  }

  static async getFeed(page: number = 1, limit: number = 20, type?: string) {
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    let query = supabase
        .from('traces')
        .select('*, profiles(username, avatar_url)') 
        .eq('visibility', 'public')
        .order('created_at', { ascending: false })
        .range(from, to);
    
    if (type && type !== 'All') {
        query = query.eq('type', type.toUpperCase());
    }

    const { data, error } = await query;
    
    if (error) throw error;
    return data;
  }

  static async likeTrace(userId: string, traceId: string) {
    await supabase.from('trace_likes').insert({ user_id: userId, trace_id: traceId });
    // AI Learning
    this.learnFromInteraction(userId, traceId, 'LIKE');
  }

  static async commentTrace(userId: string, traceId: string, content: string) {
    await supabase.from('trace_comments').insert({ user_id: userId, trace_id: traceId, content });
  }

  static async reportTrace(userId: string, traceId: string, reason: string) {
    await supabase.from('reports').insert({ reporter_id: userId, trace_id: traceId, reason });
  }

  static async getTraceDetails(traceId: string, userId?: string) {
    const { data, error } = await supabase
        .from('traces')
        .select(`
            *,
            profiles(username, avatar_url),
            trace_comments(*, profiles(username, avatar_url)),
            trace_likes(count)
        `)
        .eq('id', traceId)
        .single();
    
    if (error) throw error;

    let isUnlocked = false;
    if (userId) {
        if (data.author_id === userId) {
            isUnlocked = true;
        } else {
            const { count } = await supabase
                .from('unlocked_traces')
                .select('*', { count: 'exact', head: true })
                .eq('user_id', userId)
                .eq('trace_id', traceId);
            isUnlocked = (count || 0) > 0;
        }
    }

    return { ...data, is_unlocked: isUnlocked };
  }

  static async getNearbyHybrid(params: HybridSearchParams) {
    const { lat, long, radius, moodVector, userId } = params;
    
    // Fetch User's Identity & Mood from DB if not provided fully
    const userVectors = await UserService.getVectors(userId);
    const dbMood = userVectors?.mood;
    const dbIdentity = userVectors?.identity;

    const neutralVector = new Array(384).fill(0);
    
    // Use provided mood (search) OR stored mood OR neutral
    const searchMood = moodVector || dbMood || neutralVector;
    
    // Use stored identity OR neutral
    const searchIdentity = dbIdentity || neutralVector;

    const { data, error } = await supabase.rpc('get_traces_hybrid', {
        user_lat: lat,
        user_long: long,
        radius_meters: radius || 500,
        mood_vector: searchMood,
        identity_vector: searchIdentity,
        requesting_user_id: userId 
    });

    if (error) throw error;
    return data;
  }

  static async getInBounds(minLat: number, maxLat: number, minLong: number, maxLong: number, userId: string) {
    const { data, error } = await supabase.rpc('get_traces_in_bounds', {
      min_lat: minLat,
      min_long: minLong,
      max_lat: maxLat,
      max_long: maxLong,
      requesting_user_id: userId
    });

    if (error) throw error;
    return data;
  }

  static async search(query: string, lat: number, long: number, userId: string) {
    const { data, error } = await supabase.rpc('search_traces', {
      search_query: query,
      user_lat: lat,
      user_long: long,
      requesting_user_id: userId
    });

    if (error) throw error;
    return data;
  }

  static async unlockTrace(traceId: string, userId: string, lat: number, long: number) {
      const { data, error } = await supabase.rpc('check_distance', {
          trace_id: traceId,
          user_lat: lat,
          user_long: long
      });

      if (error) throw error;

      const result = Array.isArray(data) ? data[0] : data;
      
      if (!result) throw { status: 404, message: 'Trace result invalid' };

      if (result.unlocked) {
          try {
              await supabase.from('unlocked_traces').insert({
                  user_id: userId,
                  trace_id: traceId
              });
          } catch (e) {
              // Ignore duplicate/conflict errors
          }
          
          // AI Learning
          this.learnFromInteraction(userId, traceId, 'UNLOCK');

          return { success: true, message: 'Unlocked!', trace: await TraceService.getTraceDetails(traceId, userId) };
      } else {
          return { success: false, message: 'Too far away', distance: result.distance_meters };
      }
  }

  static async getMyTraces(userId: string) {
    const { data, error } = await supabase
        .from('traces')
        .select('*')
        .eq('author_id', userId)
        .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data;
  }

  static async getUserTraces(userId: string) {
    const { data, error } = await supabase
        .from('traces')
        .select('*')
        .eq('author_id', userId)
        .eq('visibility', 'public') // Only public traces for other users
        .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data;
  }

  static async getExplorerContent(userId: string, lat: number, long: number) {
    // 1. Fetch Traces using Hybrid Brain (Mood + Identity)
    const traces = await this.getNearbyHybrid({
        lat, long, radius: 10000, 
        userId
    });

    // 2. Fetch User Recommendations (Users with similar persona but not followed)
    const { data: userRecs } = await supabase
        .from('profiles')
        .select('id, username, avatar_url, personality_type')
        .limit(5);

    // 3. Combine into a "Discovery Stream"
    return {
        traces: traces || [],
        recommendations: userRecs || []
    };
  }
}
