FROM rust:1.96.0-bookworm AS builder
WORKDIR /build
COPY Cargo.toml Cargo.lock ./
COPY src ./src
COPY migrations ./migrations
RUN cargo build --locked --release

FROM debian:bookworm-20260824-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && rm -rf /var/lib/apt/lists/* && useradd -u 10001 -m kodo && mkdir -p /data && chown kodo:kodo /data
COPY --from=builder /build/target/release/kodo-api /usr/local/bin/kodo-api
USER kodo
ENV KODO_BIND=0.0.0.0:8080 KODO_DATABASE_URL=sqlite:///data/kodo.sqlite
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s CMD curl --fail http://127.0.0.1:8080/health/ready || exit 1
CMD ["kodo-api"]
