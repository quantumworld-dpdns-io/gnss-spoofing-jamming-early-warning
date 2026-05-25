# syntax=docker/dockerfile:1
# Stage 1: Rust build
FROM rust:1.85-slim-bookworm AS rust-builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src/detection-engine/crates/ ./src/detection-engine/crates/
COPY src/mcp-server/ ./src/mcp-server/
RUN cargo build --release --workspace

# Stage 2: Python build
FROM python:3.12-slim-bookworm AS python-builder
WORKDIR /app
COPY pyproject.toml ./
COPY src/detection-engine/python/ ./src/detection-engine/python/
RUN pip install --no-cache-dir -e "src/detection-engine/python[quantum]"

# Stage 3: Go build
FROM golang:1.23-bookworm AS go-builder
WORKDIR /app
COPY src/api-gateway/ ./src/api-gateway/
COPY go.mod go.sum ./
RUN cd src/api-gateway && CGO_ENABLED=0 go build -o /go-gateway ./cmd/

# Stage 4: Node build
FROM node:22-bookworm AS node-builder
WORKDIR /app
COPY src/frontend/package.json src/frontend/package-lock.json ./
RUN npm ci
COPY src/frontend/ ./
RUN npm run build

# Stage 5: Final runtime
FROM python:3.12-slim-bookworm AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=rust-builder /app/target/release/mcp-server /usr/local/bin/
COPY --from=go-builder /go-gateway /usr/local/bin/api-gateway
COPY --from=python-builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=node-builder /app/.next /app/.next
COPY --from=node-builder /app/public /app/public
COPY --from=node-builder /app/package.json /app/
COPY --from=node-builder /app/node_modules /app/node_modules
COPY config/prod/ /app/config/
EXPOSE 8090 8080 3000
CMD ["api-gateway"]
