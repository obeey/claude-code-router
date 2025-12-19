FROM node:20-alpine AS builder
WORKDIR /app

# Install dependencies (including dev deps) and build local package
COPY package.json package-lock.json* ./
RUN npm install
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production

# Copy built artifacts from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

# Install only production dependencies in the runtime image
RUN npm install --production --no-audit --no-fund

# Ensure the default config directory exists and use the recommended config
RUN mkdir -p /root/.claude-code-router
COPY config.recommended.json /root/.claude-code-router/config.json
RUN sed -i 's/"HOST": "127.0.0.1"/"HOST": "0.0.0.0"/' /root/.claude-code-router/config.json

EXPOSE 3456

# Run the local-built CLI
CMD ["node", "dist/cli.js", "start"]
