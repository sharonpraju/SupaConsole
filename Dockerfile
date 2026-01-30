# syntax=docker/dockerfile:1

FROM node:20-bookworm-slim AS base

# Common system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl git curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --legacy-peer-deps

# Prisma client generation needs the schema
COPY prisma ./prisma
RUN npx prisma generate

FROM deps AS builder
WORKDIR /app
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM base AS runner

# Install Docker CLI and Compose plugin so the app can manage Supabase containers
RUN apt-get update && \
    apt-get install -y --no-install-recommends gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV NEXT_TELEMETRY_DISABLED=1

# Default persistent SQLite path (can be overridden in DokPloy)
ENV DATABASE_URL=file:/app/data/db.sqlite

# Persistence mounts
RUN mkdir -p /app/data /app/supabase-core /app/supabase-projects
VOLUME ["/app/data", "/app/supabase-core", "/app/supabase-projects"]

# Copy built app and dependencies
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.* ./
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma

EXPOSE 3000

# Apply schema on start without destructive flags, then start Next.js
CMD sh -c "npx prisma db push && npm run start"