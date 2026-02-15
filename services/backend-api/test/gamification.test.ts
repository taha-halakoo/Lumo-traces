import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert';
import sinon from 'sinon';
import { buildServer } from '../src/index';
import { supabase } from '../src/lib/supabase';

test('Gamification API Flow', async (t) => {
    let server: any;
    let sbMocks: any;

    t.beforeEach(async () => {
        sbMocks = {
            from: sinon.stub(supabase, 'from'),
        };
        server = buildServer();
    });

    t.afterEach(async () => {
        sinon.restore();
        await server.close();
    });

    await t.test('POST /gamification/badges/check - Should award new badges', async () => {
        // Mock Profile
        const mockProfile = { reputation_points: 100 };
        const mockBadges = [{ id: 'badge_1', criteria: { min_reputation: 50 } }];
        
        // Mock DB calls
        // 1. Get Profile
        const profileChain = { select: sinon.stub().returns({ eq: sinon.stub().returns({ single: sinon.stub().resolves({ data: mockProfile }) }) }) };
        sbMocks.from.withArgs('profiles').returns(profileChain);
        
        // 2. Get Badges
        const badgeChain = { select: sinon.stub().resolves({ data: mockBadges }) };
        sbMocks.from.withArgs('badges').returns(badgeChain);
        
        // 3. Upsert User Badges
        const upsertChain = { 
            upsert: sinon.stub().returns({ select: sinon.stub().resolves({ data: [{ badge_id: 'badge_1' }] }) }) 
        };
        sbMocks.from.withArgs('user_badges').returns(upsertChain);

        // 4. Notification Insert (triggered by success)
        const notifyChain = { insert: sinon.stub().resolves() };
        sbMocks.from.withArgs('notifications').returns(notifyChain);

        const response = await server.inject({
            method: 'POST',
            url: '/v1/gamification/badges/check',
            headers: { 'x-user-id': 'user-1' }
        });

        assert.strictEqual(response.statusCode, 200);
        assert.strictEqual(JSON.parse(response.body).success, true);
    });

    await t.test('POST /traces/:id/infect - Should infect user', async () => {
        const insertChain = { insert: sinon.stub().resolves({ error: null }) };
        sbMocks.from.withArgs('parasitic_infections').returns(insertChain);

        const response = await server.inject({
            method: 'POST',
            url: '/v1/traces/trace-123/infect',
            headers: { 'x-user-id': 'user-1' },
            payload: { lat: 0, long: 0 }
        });

        assert.strictEqual(response.statusCode, 200);
        const body = JSON.parse(response.body);
        assert.strictEqual(body.success, true);
        assert.strictEqual(body.data.status, 'INFECTED');
    });
});
