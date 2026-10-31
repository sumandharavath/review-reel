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

