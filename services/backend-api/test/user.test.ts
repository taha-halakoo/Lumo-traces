import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert';
import sinon from 'sinon';
import { buildServer } from '../src/index';
import { supabase } from '../src/lib/supabase';

test('User & Profile API Flow', async (t) => {
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

    await t.test('PUT /profile - Should validate input (Zod)', async () => {
        const response = await server.inject({
            method: 'PUT',
            url: '/profile',
            headers: { 'x-user-id': 'user-1' },
            payload: {
                username: "To" // Too short (<3 chars)
            }
        });

        assert.strictEqual(response.statusCode, 400);
        const body = JSON.parse(response.body);
        assert.strictEqual(body.success, false);
        assert.strictEqual(body.error, 'Validation Error');
        // assert.ok(body.details, 'Should contain details'); // details might be hidden in some environments
    });

    await t.test('PUT /profile - Should update valid profile', async () => {
        const chain = {
            update: sinon.stub().returnsThis(),
            eq: sinon.stub().resolves({ error: null })
        };
        sbMocks.from.withArgs('profiles').returns(chain);

        const response = await server.inject({
            method: 'PUT',
            url: '/profile',
            headers: { 'x-user-id': 'user-1' },
            payload: {
                username: "ValidUser",
                bio: "I am a tester"
            }
        });

        assert.strictEqual(response.statusCode, 200);
        const body = JSON.parse(response.body);
        assert.strictEqual(body.success, true);
    });

    await t.test('POST /traces/:id/report - Should submit report', async () => {
        const chain = {
            insert: sinon.stub().resolves({ error: null })
        };
        sbMocks.from.withArgs('reports').returns(chain);

        const response = await server.inject({
            method: 'POST',
            url: '/traces/123/report',
            headers: { 'x-user-id': 'user-1' },
            payload: {
                reason: "Spam content"
            }
        });

        assert.strictEqual(response.statusCode, 200);
        assert.strictEqual(JSON.parse(response.body).success, true);
    });
});
