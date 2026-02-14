import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert';
import sinon from 'sinon';
import { buildServer } from '../src/index';
import { supabase } from '../src/lib/supabase';
import { RankingService } from '../src/services/rankingService';

test('Traces API Flow', async (t) => {
    let server: any;
    let sbMocks: any;

    t.beforeEach(async () => {
        // Mock AI to avoid loading model every test
        sinon.stub(RankingService, 'initAI').resolves();
        sinon.stub(RankingService, 'generateEmbedding').resolves(new Array(384).fill(0.1));
        
        // Mock Supabase
        sbMocks = {
            from: sinon.stub(supabase, 'from'),
            rpc: sinon.stub(supabase, 'rpc'),
            auth: sinon.stub(supabase.auth, 'getUser').resolves({ 
                data: { user: { id: 'user-1' } } as any, 
                error: null 
            })
        };
        server = buildServer();
    });

    t.afterEach(async () => {
        sinon.restore();
        await server.close();
    });

    await t.test('POST /v1/traces - Should create a trace successfully', async () => {
        // Mock DB Insert
        const mockTrace = { id: '123', location: 'POINT(0 0)' };
        const chain = {
            insert: sinon.stub().returnsThis(),
            select: sinon.stub().returnsThis(),
            single: sinon.stub().resolves({ data: mockTrace, error: null })
        };
        sbMocks.from.withArgs('traces').returns(chain);

        const response = await server.inject({
            method: 'POST',
            url: '/v1/traces',
            headers: { authorization: 'Bearer test-token' },
            payload: {
                lat: 40.7128,
                long: -74.0060,
                text: "Hello World",
                type: "STANDARD"
            }
        });

        assert.strictEqual(response.statusCode, 200);
        const body = JSON.parse(response.body);
        assert.strictEqual(body.success, true);
        assert.deepStrictEqual(body.data, mockTrace);
    });

    await t.test('GET /v1/traces/nearby - Should return hybrid results', async () => {
        // Mock RPC call
        const mockResults = [{ id: '1', score: 0.9 }];
        sbMocks.rpc.withArgs('get_traces_hybrid').resolves({ data: mockResults, error: null });
        
        // Mock User Profile Fetch (for search)
        const profileChain = {
            select: sinon.stub().returnsThis(),
            eq: sinon.stub().returnsThis(),
            single: sinon.stub().resolves({ data: { mood_embedding: [], identity_embedding: [] }, error: null })
        };
        sbMocks.from.withArgs('profiles').returns(profileChain);

        const response = await server.inject({
            method: 'GET',
            url: '/v1/traces/nearby?lat=40&long=-74&radius=100',
            headers: { authorization: 'Bearer test-token' }
        });

        assert.strictEqual(response.statusCode, 200);
        const body = JSON.parse(response.body);
        assert.strictEqual(body.success, true);
        assert.strictEqual(body.data[0].id, '1');
    });

    await t.test('POST /v1/traces/:id/unlock - Should fail if too far', async () => {
        // Mock RPC check_distance
        sbMocks.rpc.withArgs('check_distance').resolves({ 
            data: [{ unlocked: false, distance_meters: 50 }], 
            error: null 
        });

        const response = await server.inject({
            method: 'POST',
            url: '/v1/traces/abc-123/unlock',
            headers: { authorization: 'Bearer test-token' },
            payload: { lat: 40, long: -74 }
        });

        assert.strictEqual(response.statusCode, 200); // 200 OK because logic handled cleanly
        const body = JSON.parse(response.body);
        assert.strictEqual(body.success, false);
        assert.match(body.data.message, /Too far away/);
    });
});
