FROM node:20-alpine

ENV NODE_ENV=development
WORKDIR /app

# Install exactly from lockfile; skip audit/fund noise
COPY package*.json ./
RUN npm ci --no-audit --no-fund

# App source
COPY . .

# Run as non-root (predefined 'node' user in the base image)
RUN chown -R node:node /app
USER node

# Useful on some hosts/VMs; your API base (proxy /api → backend)
ENV CHOKIDAR_USEPOLLING=true
ENV VITE_API_BASE_URL=/api

EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173", "--strictPort"]
