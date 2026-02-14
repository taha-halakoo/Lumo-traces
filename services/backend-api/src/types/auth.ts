import { FastifyRequest } from 'fastify';

export interface AuthenticatedUser {
    id: string;
}

export interface AuthRequest extends FastifyRequest {
    user: AuthenticatedUser;
}

// Standard Response Interface
export interface ApiResponse<T> {
    success: boolean;
    data?: T;
    error?: string;
}
