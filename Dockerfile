# --- Palco 1: Builder ---
# Instala todas as dependências (dev e prod) e compila o projeto.
FROM node:22.19.0-alpine AS builder
WORKDIR /usr/src/wpp-server
ENV NODE_ENV=development

# Instala dependências de sistema para compilação (incluindo para o 'sharp')
RUN apk add --no-cache vips-dev fftw-dev gcc g++ make libc6-compat

# Copia os arquivos de definição de dependências
COPY package.json ./

# Instala todas as dependências
RUN yarn install

# Copia o restante do código-fonte
COPY . .

# Compila o projeto
RUN yarn build


# --- Palco 2: Runner (Imagem Final) ---
# Cria a imagem final apenas com o necessário para rodar.
FROM node:22.19.0-alpine
WORKDIR /usr/src/wpp-server
ENV NODE_ENV=production

# Define a porta da aplicação como uma variável de ambiente
ENV PORT=21465

# Instala dependências de sistema APENAS para rodar (vips, chromium, e curl para healthcheck)
RUN apk add --no-cache vips fftw chromium curl

# Copia os arquivos de definição de dependências e os módulos de produção do palco 'builder'
COPY --from=builder /usr/src/wpp-server/package.json ./
COPY --from=builder /usr/src/wpp-server/node_modules ./node_modules

# Copia o código compilado do palco 'builder'
COPY --from=builder /usr/src/wpp-server/dist ./dist

# Expõe a porta definida na variável de ambiente
EXPOSE $PORT

# Adiciona a verificação de saúde (Health Check) usando a variável de ambiente
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:${PORT}/api-docs/ || exit 1

ENTRYPOINT ["node", "dist/server.js"]

