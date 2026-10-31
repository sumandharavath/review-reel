# Review Reel

# Discover, review and book the movies you love

Step 1: Create the Project Directory Structure

Open your terminal in /Users/sumandharavath/My Projects/review-reel and run:

bash
mkdir -p apps/mobile apps/admin services/api packages/api-contract infra docs .github/workflows

To make sure Git tracks these folders before we put code in them:

bash
touch apps/mobile/.gitkeep \
 apps/admin/.gitkeep \
 services/api/.gitkeep \
 packages/api-contract/.gitkeep \
 infra/.gitkeep \
 docs/.gitkeep \
 .github/workflows/.gitkeep
Step 2: Initialize the Backend (services/api)

Navigate to the services/api directory:

bash
cd services/api

Initialize a Node project and install the core TypeScript & Express packages:

bash

# 1. Create package.json

npm init -y

# 2. Install production dependencies

npm install express dotenv cors helmet morgan

# 3. Install development dependencies (TypeScript + type definitions + dev server)

npm install -D typescript tsx @types/node @types/express @types/cors @types/morgan

Initialize the TypeScript configuration:

bash
npx tsc --init
Step 3: Initialize Prisma and Connect to PostgreSQL

While still inside services/api:

bash

# 1. Install Prisma

npm install @prisma/client
npm install -D prisma

# 2. Initialize Prisma (creates prisma/schema.prisma and .env)

npx prisma init
