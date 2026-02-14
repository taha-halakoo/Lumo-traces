import { FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { TraceService } from '../services/traceService';
import { RankingService } from '../services/rankingService';

// Zod Schemas
const nearbySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  long: z.coerce.number().min(-180).max(180),
  radius: z.coerce.number().min(0).max(10000).optional().default(500),
  searchText: z.string().optional()
});

const createTraceSchema = z.object({
  lat: z.number().min(-90).max(90),
  long: z.number().min(-180).max(180),
  text: z.string().optional(),
  type: z.enum(['STANDARD', 'STORY', 'CHALLENGE', 'ORB', 'FRIEND']).default('STANDARD'),
  visibility: z.enum(['public', 'private', 'friends']).default('public')
});

const unlockSchema = z.object({
    lat: z.number(),
    long: z.number()
});

export class TraceController {
  
  static async getNearby(req: FastifyRequest, reply: FastifyReply) {
    const parseResult = nearbySchema.safeParse(req.query);
    
    if (!parseResult.success) {
        const err = new Error('Invalid query parameters');
        (err as any).statusCode = 400;
        (err as any).validation = (parseResult as any).error.errors;
        throw err;
    }

    const { lat, long, radius, searchText } = parseResult.data;

    try {
        const user = (req as any).user; 
        let moodVector: number[] = [];

        if (searchText) {
            moodVector = await RankingService.generateEmbedding(searchText);
        }

        const traces = await TraceService.getNearbyHybrid({
            lat,
            long,
            radius,
            moodVector: moodVector.length > 0 ? moodVector : undefined,
            userId: user ? user.id : undefined
        });

        return reply.send(traces);
    } catch (err) {
        throw err;
    }
  }

  static async create(req: FastifyRequest, reply: FastifyReply) {
    const parseResult = createTraceSchema.safeParse(req.body);
    
    if (!parseResult.success) {
        const err = new Error('Invalid body');
        (err as any).statusCode = 400;
        (err as any).validation = (parseResult as any).error.errors;
        throw err;
    }

    const body = parseResult.data;
    const user = (req as any).user;

    try {
        let embedding: number[] = [];
        if (body.text) {
             embedding = await RankingService.generateEmbedding(body.text);
        }

        const trace = await TraceService.createTrace(user.id, { ...body, embedding });
        return reply.send(trace);
    } catch (err) {
        throw err;
    }
  }

  static async unlock(req: FastifyRequest, reply: FastifyReply) {
    const { id } = req.params as { id: string };
    const parseResult = unlockSchema.safeParse(req.body);

    if (!parseResult.success) {
        const err = new Error('Invalid location data');
        (err as any).statusCode = 400;
        throw err;
    }
    
    const { lat, long } = parseResult.data;
    const user = (req as any).user;

    try {
        const result = await TraceService.unlockTrace(id, user.id, lat, long);
        return reply.send(result);
    } catch (err) {
        throw err;
    }
  }

  static async getFeed(req: FastifyRequest, reply: FastifyReply) {
    const { page, limit } = req.query as { page?: string, limit?: string };
    const p = parseInt(page || '1');
    const l = parseInt(limit || '20');
    
    const traces = await TraceService.getFeed(p, l);
    return reply.send(traces);
  }

  static async getDiscovery(req: FastifyRequest, reply: FastifyReply) {
    const user = (req as any).user;
    const content = await TraceService.getExplorerContent(user.id);
    return reply.send(content);
  }

  static async getMyTraces(req: FastifyRequest, reply: FastifyReply) {
    const user = (req as any).user;
    const traces = await TraceService.getMyTraces(user.id);
    return reply.send(traces);
  }

  static async getUserTraces(req: FastifyRequest, reply: FastifyReply) {
    const { userId } = req.params as { userId: string };
    const traces = await TraceService.getUserTraces(userId);
    return reply.send(traces);
  }

  static async getDetails(req: FastifyRequest, reply: FastifyReply) {
    const { id } = req.params as { id: string };
    const user = (req as any).user;
    const trace = await TraceService.getTraceDetails(id, user?.id);
    return reply.send(trace);
  }

  static async like(req: FastifyRequest, reply: FastifyReply) {
    const user = (req as any).user;
    const { id } = req.params as { id: string };
    await TraceService.likeTrace(user.id, id);
    return reply.send({ success: true });
  }

  static async comment(req: FastifyRequest, reply: FastifyReply) {
    const user = (req as any).user;
    const { id } = req.params as { id: string };
    const { content } = req.body as { content: string };
    if (!content) throw { status: 400, message: 'Content required' };
    await TraceService.commentTrace(user.id, id, content);
    return reply.send({ success: true });
  }
}
