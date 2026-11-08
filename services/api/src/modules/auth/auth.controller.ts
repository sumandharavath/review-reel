import { Request, Response } from 'express';
import { authService } from './auth.service';
import { registerSchema, loginSchema } from './auth.schema';
import { AuthenticatedRequest } from '../../middleware/auth.middleware';

export class AuthController {
  async register(req: Request, res: Response): Promise<void> {
    try {
      const parsed = registerSchema.safeParse(req.body);
      if (!parsed.success) {
        res.status(400).json({
          status: 'error',
          message: parsed.error.issues[0]?.message || 'Validation failed',
          errors: parsed.error.issues,
        });
        return;
      }

      const result = await authService.register(parsed.data);
      res.status(201).json({
        status: 'success',
        message: 'Registration successful',
        data: result,
      });
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        status: 'error',
        message: error.message || 'Internal server error',
      });
    }
  }

  async login(req: Request, res: Response): Promise<void> {
    try {
      const parsed = loginSchema.safeParse(req.body);
      if (!parsed.success) {
        res.status(400).json({
          status: 'error',
          message: parsed.error.issues[0]?.message || 'Validation failed',
          errors: parsed.error.issues,
        });
        return;
      }

      const result = await authService.login(parsed.data);
      res.status(200).json({
        status: 'success',
        message: 'Login successful',
        data: result,
      });
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        status: 'error',
        message: error.message || 'Internal server error',
      });
    }
  }

  async getMe(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      if (!req.user?.id) {
        res.status(401).json({ status: 'error', message: 'Unauthorized' });
        return;
      }

      const user = await authService.getMe(req.user.id);
      res.status(200).json({
        status: 'success',
        data: { user },
      });
    } catch (error: any) {
      const statusCode = error.statusCode || 500;
      res.status(statusCode).json({
        status: 'error',
        message: error.message || 'Internal server error',
      });
    }
  }

  async logout(_req: Request, res: Response): Promise<void> {
    // JWT is stateless; client removes stored token. Endpoint confirms logout.
    res.status(200).json({
      status: 'success',
      message: 'Logged out successfully',
    });
  }
}

export const authController = new AuthController();

