FROM node:20-alpine AS builder

WORKDIR /app

# Copy file project, kecuali node_modules
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
COPY . .

# Install dependencies di dalam Docker (agar native module cocok dengan OS Linux)
RUN yarn install

# Build Nuxt
RUN yarn build

# Tahap untuk menjalankan aplikasi
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app ./

EXPOSE 3000
CMD ["npm", "run", "preview"]
