FROM node:22-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY tsconfig.json ./
COPY init.sql ./
COPY src ./src
EXPOSE 3001
CMD ["npx", "tsx", "src/index.ts"]
