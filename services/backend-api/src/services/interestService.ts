import { supabase } from '../lib/supabase';

export class InterestService {
  
  /**
   * Updates a user's interest graph by adding weight to specific tags.
   * Caps the score at 100.
   */
  static async updateInterests(userId: string, tags: string[], weight: number) {
    if (!tags || tags.length === 0) return;

    // Fetch current graph
    const { data, error } = await supabase
      .from('profiles')
      .select('interests_graph')
      .eq('id', userId)
      .single();

    if (error) {
        console.error('Error fetching interest graph:', error);
        return; 
    }

    const currentGraph = (data?.interests_graph as Record<string, number>) || {};

    // Update locally
    tags.forEach(tag => {
      const safeTag = tag.toLowerCase().trim();
      if (!safeTag) return;
      const oldScore = currentGraph[safeTag] || 0;
      currentGraph[safeTag] = Math.min(oldScore + weight, 100); 
    });

    // Save back
    const { error: updateError } = await supabase
      .from('profiles')
      .update({ interests_graph: currentGraph })
      .eq('id', userId);
      
    if (updateError) {
        console.error('Error updating interest graph:', updateError);
    }
  }

  /**
   * Triggers the global decay of interests.
   * Should be called by a cron job or admin endpoint.
   */
  static async decayAllInterests(factor: number = 0.95) {
     const { error } = await supabase.rpc('decay_all_interests', { decay_factor: factor });
     if (error) throw error;
  }
}
