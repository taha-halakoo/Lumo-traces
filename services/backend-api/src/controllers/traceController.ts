import { FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { TraceService } from '../services/traceService';
import { RankingService } from '../services/rankingService';
import { GamificationService } from '../services/gamificationService';

// Zod Schemas
const nearbySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  long: z.coerce.number().min(-180).max(180),
  radius: z.coerce.number().min(0).max(10000).optional().default(500),
  searchText: z.string().optional()
});

const discoverySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  long: z.coerce.number().min(-180).max(180)
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

const infectSchema = z.object({
    lat: z.number(),
    long: z.number()
});

const boundsSchema = z.object({
  minLat: z.coerce.number(),
  maxLat: z.coerce.number(),
  minLong: z.coerce.number(),
  maxLong: z.coerce.number()
});

const searchSchema = z.object({
  query: z.string().min(1),
  lat: z.coerce.number().optional().default(0),
  long: z.coerce.number().optional().default(0)
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

  static async getInBounds(req: FastifyRequest, reply: FastifyReply) {
    const parseResult = boundsSchema.safeParse(req.query);
    if (!parseResult.success) {
      const err = new Error('Invalid bounds');
      (err as any).statusCode = 400;
      throw err;
    }
    const { minLat, maxLat, minLong, maxLong } = parseResult.data;
    const user = (req as any).user;
    
    const traces = await TraceService.getInBounds(minLat, maxLat, minLong, maxLong, user.id);
    return reply.send(traces);
  }

  static async search(req: FastifyRequest, reply: FastifyReply) {
    const parseResult = searchSchema.safeParse(req.query);
    if (!parseResult.success) {
      const err = new Error('Invalid search');
      (err as any).statusCode = 400;
      throw err;
    }
    const { query, lat, long } = parseResult.data;
    const user = (req as any).user;
    
    const traces = await TraceService.search(query, lat, long, user.id);
    return reply.send(traces);
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
    const { page, limit, type } = req.query as { page?: string, limit?: string, type?: string };
    const p = parseInt(page || '1');
    const l = parseInt(limit || '20');
    
    const traces = await TraceService.getFeed(p, l, type);
    return reply.send(traces);
  }

  static async getDiscovery(req: FastifyRequest, reply: FastifyReply) {
    const parseResult = discoverySchema.safeParse(req.query);
    if (!parseResult.success) {
         // Default to 0,0 if not provided or invalid? Or throw?
         // For explorer, let's default to user's last known location or 0,0 if failing.
         // But better to fail if client sends garbage.
         // However, existing clients might not send lat/long yet.
         // Let's use 0,0 as fallback if parsing fails but log it?
         // No, let's enforce it for "Production Ready".
    }
    
    // For backwards compatibility during dev, if no lat/long, use 0,0.
    const lat = parseResult.success ? parseResult.data.lat : 0;
    const long = parseResult.success ? parseResult.data.long : 0;

    const user = (req as any).user;
    const content = await TraceService.getExplorerContent(user.id, lat, long);
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

  static async report(req: FastifyRequest, reply: FastifyReply) {
    const user = (req as any).user;
    const { id } = req.params as { id: string };
    const { reason } = req.body as { reason: string };
    if (!reason) throw { status: 400, message: 'Reason required' };
    await TraceService.reportTrace(user.id, id, reason);
    return reply.send({ success: true });
  }

  static async infect(req: FastifyRequest, reply: FastifyReply) {
    const { id } = req.params as { id: string };
    const parseResult = infectSchema.safeParse(req.body);

    if (!parseResult.success) {
        const err = new Error('Invalid location data');
        (err as any).statusCode = 400;
        throw err;
    }
    
    const { lat, long } = parseResult.data;
    const user = (req as any).user;

    try {
        const result = await GamificationService.handleInfection(user.id, id, lat, long);
        return reply.send(result);
    } catch (err) {
        throw err;
    }
  }
}

