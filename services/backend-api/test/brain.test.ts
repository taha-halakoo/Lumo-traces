import { test } from 'node:test';
import assert from 'node:assert';
import { RankingService } from '../src/services/rankingService';

test('Brain Logic: AI Embedding Generator', async (t) => {
    // 1. Initialize
    await RankingService.initAI();

    // 2. Generate Vector
    const text = "I love coffee and coding";
    const vector = await RankingService.generateEmbedding(text);

    // 3. Verify
    assert.strictEqual(Array.isArray(vector), true, 'Output should be an array');
    assert.strictEqual(vector.length, 384, 'Vector should have 384 dimensions (MiniLM-L6-v2 standard)');
    
    // 4. Sanity Check (Values should be floats between -1 and 1)
    const isNormalized = vector.every(n => n >= -1.0 && n <= 1.0);
    assert.strictEqual(isNormalized, true, 'Vector values should be normalized');
});

test('Brain Logic: Cosine Similarity', async (t) => {
    // 1. Generate two similar vectors
    const v1 = await RankingService.generateEmbedding("coffee");
    const v2 = await RankingService.generateEmbedding("espresso");
    const v3 = await RankingService.generateEmbedding("skateboard");

    // 2. Calculate Scores
    // We mock the service internal math or check logical outcomes if exposing helper
    // Since 'calculateScore' is static, we can test it if we mock the profile/trace objects
    
    const profile = { identity: v1, mood: v1 }; // Obsessed with coffee
    const traceCoffee = { embedding: v2, type: 'STANDARD' as const, location: { lat: 0, long: 0 }, timestamp: Date.now() };
    const traceSkate = { embedding: v3, type: 'STANDARD' as const, location: { lat: 0, long: 0 }, timestamp: Date.now() };

    const scoreCoffee = RankingService.calculateScore(profile, traceCoffee, 0);
    const scoreSkate = RankingService.calculateScore(profile, traceSkate, 0);

    // 3. Verify Logic
    assert.ok(scoreCoffee > scoreSkate, 'Coffee should be more relevant than Skateboard for a coffee lover');
});
