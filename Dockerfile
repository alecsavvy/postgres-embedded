# syntax=docker/dockerfile:1.4
FROM debian:bookworm-slim

# Install Postgres, client tools, and tini for clean PID 1 handling
RUN apt-get update && \
    apt-get install -y postgresql postgresql-client postgresql-contrib tini bash && \
    rm -rf /var/lib/apt/lists/*

# Prepare data and socket directories
RUN mkdir -p /data /var/run/postgresql && \
    chown -R postgres:postgres /data /var/run/postgresql

USER postgres

# Initialize the Postgres data directory
RUN initdb -D /data

# Configure Postgres for socket-only access and lightweight settings
RUN echo "listen_addresses = ''" >> /data/postgresql.conf && \
    echo "unix_socket_directories = '/var/run/postgresql'" >> /data/postgresql.conf && \
    echo "log_destination = 'stderr'" >> /data/postgresql.conf && \
    echo "logging_collector = off" >> /data/postgresql.conf && \
    echo "shared_buffers = 64MB" >> /data/postgresql.conf && \
    echo "fsync = off" >> /data/postgresql.conf && \
    echo "synchronous_commit = off" >> /data/postgresql.conf

# Environment so psql just works
ENV PGHOST=/var/run/postgresql \
    PGUSER=postgres \
    PGDATABASE=postgres

# Script that starts Postgres in background, waits until ready, then execs user command
COPY <<'EOF' /usr/local/bin/with-postgres
#!/usr/bin/env bash
set -euo pipefail

echo "Starting embedded Postgres..."
postgres -D /data -c config_file=/data/postgresql.conf &
pg_pid=$!

# Wait for Postgres socket to become available
for i in {1..30}; do
  if [ -S /var/run/postgresql/.s.PGSQL.5432 ]; then
    echo "Postgres is ready."
    break
  fi
  echo "Waiting for Postgres..."
  sleep 0.5
done

# Run user command (from CMD/ENTRYPOINT)
echo "Executing: $*"
exec "$@" &
app_pid=$!

# Forward signals and wait on both
trap "echo 'Stopping...'; kill -TERM $pg_pid $app_pid 2>/dev/null" SIGTERM SIGINT

wait -n $pg_pid $app_pid
EOF

RUN chmod +x /usr/local/bin/with-postgres

# tini handles signal propagation, with-postgres manages lifecycle
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/with-postgres"]

# Default just runs Postgres (useful for debugging)
CMD ["bash"]
