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

# Instala dependências de sistema APENAS para rodar
RUN apk add --no-cache vips fftw chromium

# Copia os módulos de produção e o código compilado do palco 'builder'
COPY --from=builder /usr/src/wpp-server/node_modules ./node_modules
COPY --from=builder /usr/src/wpp-server/dist ./dist

EXPOSE 3000

ENTRYPOINT ["node", "dist/server.js"]
