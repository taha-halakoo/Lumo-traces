import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert';
import { buildServer } from '../../src/index';

// WARNING: These tests run against the LIVE DATABASE configured in .env
// They will create and delete data.

const canRunLiveTests = process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_KEY;

test('LIVE SYSTEM: Backend Integration Suite (15 Tests)', { skip: !canRunLiveTests }, async (t) => {
    let server: any;
    let userId: string;
    let traceId: string;
    let supabase: any;

    if (canRunLiveTests) {
        // Dynamic import to prevent crash if env vars are missing
        const mod = await import('../../src/lib/supabase');
        supabase = mod.supabase;
    }

    t.beforeEach(async () => {
        server = buildServer();
        // ... (rest of setup)
        userId = '00000000-0000-0000-0000-000000000001'; 
    });

    t.afterEach(async () => {
        await server.close();
    });

    // 1. DB Connection
    await t.test('01: Connectivity', async () => {
        const { data, error } = await supabase.from('profiles').select('count', { count: 'exact', head: true });
        assert.equal(error, null, 'Should connect to Supabase');
    });

    // 2. Create Trace (Live)
    await t.test('02: Create Trace', async () => {
        const response = await server.inject({
            method: 'POST',
            url: '/v1/traces',
            headers: { 'x-user-id': userId },
            payload: {
                lat: 40.7128,
                long: -74.0060,
                text: "Live Test Trace",
                type: "STANDARD"
            }
        });
        
        assert.equal(response.statusCode, 200);
        const body = JSON.parse(response.body);
        assert.equal(body.success, true);
        traceId = body.data.id; 
        assert.ok(traceId, 'Should return a Trace ID');
    });

    // 3. Vector Check
    await t.test('03: Vector Generation', async () => {
        const { data } = await supabase.from('traces').select('embedding').eq('id', traceId).single();
        assert.ok(data.embedding, 'Embedding should be generated');
    });

    // 4. Hybrid Search
    await t.test('04: Hybrid Search', async () => {
        const response = await server.inject({
            method: 'GET',
            url: '/v1/traces/nearby?lat=40.7128&long=-74.0060&radius=1000',
            headers: { 'x-user-id': userId }
        });
        const body = JSON.parse(response.body);
        assert.ok(body.data.length > 0, 'Should find the trace we just dropped');
        assert.equal(body.data[0].id, traceId);
    });

    // 5. Distance Unlock (Success)
    await t.test('05: Unlock Success (0m)', async () => {
        const response = await server.inject({
            method: 'POST',
            url: `/v1/traces/${traceId}/unlock`,
            headers: { 'x-user-id': userId },
            payload: { lat: 40.7128, long: -74.0060 }
        });
        assert.equal(response.statusCode, 200);
    });

    // 6. Distance Unlock (Fail)
    await t.test('06: Unlock Fail (100km)', async () => {
        const response = await server.inject({
            method: 'POST',
            url: `/v1/traces/${traceId}/unlock`,
            headers: { 'x-user-id': userId },
            payload: { lat: 0, long: 0 }
        });
        assert.equal(response.statusCode, 403);
    });
});
