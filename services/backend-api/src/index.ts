import dotenv from 'dotenv';
dotenv.config();

import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import { RankingService } from './services/rankingService';
import { appRoutes } from './routes';
import { requireAuth } from './middleware/auth';

export const buildServer = () => {
    const server = Fastify({ logger: true });

    // Global Middleware
    server.register(helmet); // Security Headers
    server.register(cors, { 
        origin: (origin, cb) => {
            // Allow mobile apps (no origin) and localhost
            if (!origin || origin.startsWith('http://localhost') || origin.startsWith('http://10.0.2.2') || origin.startsWith('http://192.168')) {
                cb(null, true);
                return;
            }
            cb(new Error('Not allowed'), false);
        }
    });
    server.register(rateLimit, {
        max: 100,
        timeWindow: '1 minute'
    });

    // Response Standardizer
    server.addHook('onSend', async (request, reply, payload) => {
        if (reply.statusCode >= 400) return payload;
        try {
            const parsed = JSON.parse(payload as string);
            // If it's already an object with 'success' field, don't re-wrap it
            if (parsed && typeof parsed === 'object' && parsed.success !== undefined) {
                // If it doesn't have 'data', and it's intended to be the data itself, 
                // we might still want to wrap it, BUT for our specific services 
                // that return {success, message}, we should respect it.
                return payload;
            }
            return JSON.stringify({ success: true, data: parsed });
        } catch (e) {
            return JSON.stringify({ success: true, data: payload });
        }
    });

    // Global Error Handler
    server.setErrorHandler((error, request, reply) => {
        request.log.error(error);
        reply.status(error.statusCode || 500).send({
            success: false,
            error: error.message || 'Internal Server Error'
        });
    });

    // Register All App Routes (v1)
    server.register(appRoutes, { prefix: '/v1' });

    // Legacy/Root Routes (Keeping for backward compatibility or health checks)
    server.get('/', async () => ({ status: 'ok', service: 'Traces API', version: '2.0-LIQUID' }));
    
    return server;
};

import { fileURLToPath } from 'url';
import path from 'path';

// Start Logic (Only if run directly)
const nodePath = path.resolve(process.argv[1]);
const modulePath = path.resolve(fileURLToPath(import.meta.url));

if (nodePath === modulePath) {
    const start = async () => {
        try {
            console.log('Warming up AI Brain...');
            await RankingService.initAI();
            const server = buildServer();
            const port = process.env.PORT ? parseInt(process.env.PORT) : 3000;
            await server.listen({ port, host: '0.0.0.0' });
            console.log(`Server running at http://0.0.0.0:${port}`);
        } catch (err) {
            console.error(err);
            process.exit(1);
        }
    };
    start();
}

