import { similarity } from 'ml-distance';
import { VectorSearchService } from './vectorSearchService';

// Pure Math & Logic Only - No Database Calls

interface VectorProfile {
  identity: number[]; 
  mood: number[];     
}

interface TraceVector {
  embedding: number[];
  type: 'STANDARD' | 'STORY' | 'CHALLENGE' | 'ORB';
  location: { lat: number; long: number };
  timestamp: number;
}

export class RankingService {
  // Weights
  private static MOOD_WEIGHT = 0.4;
  private static IDENTITY_WEIGHT = 0.2;
  private static DISTANCE_WEIGHT = 0.3;
  private static RECENCY_WEIGHT = 0.1;

  // Delegate to VectorSearchService
  static async initAI() {
    await VectorSearchService.initAI();
  }

  static async generateEmbedding(text: string): Promise<number[]> {
    return await VectorSearchService.generateEmbedding(text);
  }

  static calculateScore(user: VectorProfile, trace: TraceVector, distanceMeters: number): number {
    const moodScore = similarity.cosine(user.mood, trace.embedding);
    const identityScore = similarity.cosine(user.identity, trace.embedding);
    const distanceScore = Math.max(0, 1 - (distanceMeters / 1000)); 
    const hoursOld = (Date.now() - trace.timestamp) / (1000 * 60 * 60);
    const recencyScore = Math.max(0, 1 - (hoursOld / 48)); 

    let typeMultiplier = 1.0;
    if (trace.type === 'ORB') typeMultiplier = 1.5; 
    if (trace.type === 'CHALLENGE') typeMultiplier = 1.2;

    const finalScore = (
      (moodScore * this.MOOD_WEIGHT) +
      (identityScore * this.IDENTITY_WEIGHT) +
      (distanceScore * this.DISTANCE_WEIGHT) +
      (recencyScore * this.RECENCY_WEIGHT)
    ) * typeMultiplier;

    return Math.min(finalScore, 1.0); 
  }

  /**
   * Pure Math: Calculates the new mood vector.
   * Mood changes quickly (70% old, 30% new).
   */
  static calculateNewMood(currentMood: number[], traceEmbedding: number[]): number[] {
    if (!currentMood || currentMood.length === 0) return traceEmbedding;
    return currentMood.map((val, i) => (val * 0.7) + (traceEmbedding[i] * 0.3));
  }

  /**
   * Pure Math: Calculates the new identity vector.
   * Identity changes slowly (95% old, 5% new).
   */
  static calculateNewIdentity(currentIdentity: number[], traceEmbedding: number[]): number[] {
    if (!currentIdentity || currentIdentity.length === 0) return traceEmbedding;
    return currentIdentity.map((val, i) => (val * 0.95) + (traceEmbedding[i] * 0.05));
  }
}
