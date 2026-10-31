# Phase 0: Project Setup & Database Connection Guide

This guide documents the setup completed for **Review Reel**'s backend foundation, including all terminal commands executed, why specific architectural choices were made, and a comprehensive step-by-step walkthrough for reproducing this setup manually.

---

## 1. Summary of What Was Done

1. **System & Tooling Verification**:
   - Confirmed Node.js (`v24.15.0`), npm (`11.12.1`), and PostgreSQL (`18.4`) installed on macOS.
   - Verified the existing database `review_reel_dev` in PostgreSQL and authenticated with the `postgres` superuser using password `root`.

2. **Git Hygiene & Ignore Rules**:
   - Resolved an accidental commit containing `node_modules/` by performing a soft reset (`git reset HEAD~1`).
   - Appended proper Node and environment exclusion patterns (`node_modules/`, `dist/`, `.env`, `.env.*`) to the root `.gitignore`.
   - Prevented credentials and large binaries from polluting the remote Git repository.

3. **Prisma ORM & PostgreSQL Configuration**:
   - Pinned **Prisma 6.19.3** and `@prisma/client 6.19.3` for standard, stable support of `url = env("DATABASE_URL")` with PostgreSQL.
   - Created `services/api/prisma/schema.prisma` with an initial `User` model mapped to the `users` table.
   - Synchronized the schema with PostgreSQL via `prisma db push`, generating the strongly-typed Prisma Client.
   - Created `services/api/.env` (gitignored) containing the active connection string and `services/api/.env.example` as a template.

4. **Modular Express Server & Health Check Route**:
   - **`src/lib/prisma.ts`**: Implemented a singleton pattern for `PrismaClient` to avoid connection pool exhaustion during hot reload.
   - **`src/app.ts`**: Configured Express with security headers (`helmet`), CORS (`cors`), request logging (`morgan`), JSON body parsing, and a live `/health` endpoint that validates DB health with a `SELECT 1` query.
   - **`src/server.ts`**: Server listener on port `5001` with graceful shutdown handling for `SIGTERM` and `SIGINT`.
   - Verified the endpoint live via `curl http://localhost:5001/health`.

---

## 2. Commands Executed

### A. Git History Fix & Security
```bash
# Undo previous commit without losing modified files on disk
git reset HEAD~1

# Ensure Node & secrets are ignored in root .gitignore
# (Appended node_modules/, dist/, .env, etc.)

# Stage and commit clean directory skeleton
git add .
git commit -m "chore: initialize project setup and directory structure"
git push -u origin chore/initial-project-setup
```

### B. Dependency Installation (inside `services/api`)
```bash
cd services/api

# Install runtime dependencies
npm install express dotenv cors helmet morgan @prisma/client@6.19.3

# Install dev dependencies
npm install -D typescript tsx @types/node @types/express @types/cors @types/morgan prisma@6.19.3
```

### C. Database Synchronization
```bash
# Push schema changes directly to review_reel_dev and generate @prisma/client
npx prisma db push
```

### D. TypeScript Validation & Server Execution
```bash
# Type-check TypeScript codebase
npx tsc --noEmit

# Start development server
npm run dev

# Verify live health check endpoint
curl -s http://localhost:5001/health
```

---

## 3. How to Do It Manually from Scratch

If you were to recreate this setup from zero on any new machine, follow these steps:

### Step 1: Create Database in PostgreSQL
1. Launch **pgAdmin 4** (or connect via terminal `psql -U postgres -h localhost`).
2. Right click **Databases** -> **Create** -> **Database...**
3. Set the Database name to `review_reel_dev` and click **Save**.

---

### Step 2: Initialize Node.js & TypeScript in `services/api`
```bash
mkdir -p services/api
cd services/api
npm init -y
```

Install the dependencies:
```bash
# Production dependencies
npm install express dotenv cors helmet morgan @prisma/client@6.19.3

# Development dependencies
npm install -D typescript tsx @types/node @types/express @types/cors @types/morgan prisma@6.19.3
```

---

### Step 3: Configure `tsconfig.json`
Create or edit `services/api/tsconfig.json` with modern Node settings:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "preserve",
    "moduleResolution": "bundler",
    "rootDir": "./src",
    "outDir": "./dist",
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"]
}
```

---

### Step 4: Configure Environment Variables
Create `services/api/.env` (ensure it is gitignored):
```env
PORT=5001
DATABASE_URL="postgresql://postgres:root@localhost:5432/review_reel_dev?schema=public"
```

Create `services/api/.env.example` (committed to git for collaborators):
```env
PORT=5001
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/review_reel_dev?schema=public"
```

---

### Step 5: Define Prisma Schema
Create `services/api/prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String?
  role      String   @default("USER")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("users")
}
```

Run `npx prisma db push` to create the table in PostgreSQL and generate the TypeScript client:
```bash
npx prisma db push
```

---

### Step 6: Create the Express App Code

#### 1. Prisma Singleton (`services/api/src/lib/prisma.ts`):
```typescript
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
```

#### 2. Express Setup & Health Route (`services/api/src/app.ts`):
```typescript
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

// Health check route verifying database connection
app.get('/health', async (_req: Request, res: Response) => {
  try {
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

app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});
```

#### 3. Server Startup (`services/api/src/server.ts`):
```typescript
import dotenv from 'dotenv';
dotenv.config();

import { app } from './app';

const PORT = process.env.PORT || 5001;

const server = app.listen(PORT, () => {
  console.log(`🎬 Review Reel API server running on http://localhost:${PORT}`);
  console.log(`🏥 Health check at: http://localhost:${PORT}/health`);
});

const shutdown = async () => {
  console.log('\nGracefully shutting down server...');
  server.close(() => {
    console.log('HTTP server closed.');
    process.exit(0);
  });
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
```

---

### Step 7: Configure npm Scripts in `package.json`
Add these scripts into `services/api/package.json`:

```json
"scripts": {
  "dev": "tsx watch src/server.ts",
  "build": "tsc",
  "start": "node dist/server.js",
  "prisma:generate": "prisma generate",
  "prisma:push": "prisma db push",
  "prisma:migrate": "prisma migrate dev",
  "prisma:studio": "prisma studio"
}
```

---

### Step 8: Verify the Server
```bash
npm run dev
```

Open a new terminal window:
```bash
curl http://localhost:5001/health
```

Expected output:
```json
{
  "status": "ok",
  "service": "review-reel-api",
  "timestamp": "2026-10-31T19:10:55.138Z",
  "database": "connected"
}
```

---

## 4. Key Gotchas & Best Practices

1. **Prisma Versioning**:
   - `npm install -D prisma` currently installs an unreleased `8.0.0-rc` platform engine, which removes standard commands like `prisma generate` and `url = env("DATABASE_URL")`.
   - Explicitly pin Prisma to version `6.19.3` (`prisma@6.19.3` and `@prisma/client@6.19.3`) for stable database integration.

2. **Git Tracking of Sensitive Files**:
   - Never commit `.env`. Always provide a sanitized `.env.example` so teammates or CI pipelines know which environment keys are required.
   - Always verify with `git status` that `node_modules/` is not tracked.
