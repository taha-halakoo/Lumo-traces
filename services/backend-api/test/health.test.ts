import { test } from 'node:test';
import assert from 'node:assert';
import { buildServer } from '../src/index';

test('Health Check', async (t) => {
  const server = buildServer();

  const response = await server.inject({
    method: 'GET',
    url: '/'
  });

  assert.strictEqual(response.statusCode, 200);
  const body = JSON.parse(response.body);
  assert.strictEqual(body.data.status, 'ok');
  assert.strictEqual(body.success, true);
});
