# Stage 1: Build the Nuxt.js application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock)
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Build the Nuxt.js application
RUN yarn build

# Stage 2: Serve the Nuxt.js application
FROM node:20-alpine

WORKDIR /app

# Copy only the necessary files from the builder stage
COPY --from=builder /app/.output ./.output
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/nuxt.config.ts ./nuxt.config.ts
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/public ./public

# Set production environment
ENV NODE_ENV=production

# Expose the port Nuxt.js runs on (default is 3000)
EXPOSE 3000

# Command to run the Nuxt.js application
CMD ["node", ".output/server/index.mjs"]
