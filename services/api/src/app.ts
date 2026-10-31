import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { prisma } from './lib/prisma';

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Basic Health Check Endpoint
app.get('/health', async (_req: Request, res: Response) => {
  try {
    // Verify database connectivity
    await prisma.$queryRaw`SELECT 1`;

    res.status(200).json({
      status: 'ok',
      service: 'review-reel-api',
      timestamp: new Date().toISOString(),
      database: 'connected',
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      service: 'review-reel-api',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: error instanceof Error ? error.message : 'Unknown database error',
    });
  }
});

// Fallback 404 handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});

