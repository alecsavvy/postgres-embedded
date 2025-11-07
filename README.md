# postgres-embedded

A lightweight Docker image with PostgreSQL pre-initialized and running in the background. Your application runs in the same container and connects via Unix socket.

## Connection String

For Go with `lib/pq`:
```
host=/var/run/postgresql user=postgres dbname=postgres sslmode=disable
```

For Go with `pgx`:
```
postgres://postgres@/postgres?host=/var/run/postgresql
```

For other languages/drivers, the format may vary:
- **Host**: `/var/run/postgresql` (Unix socket directory)
- **User**: `postgres`
- **Database**: `postgres`

## Usage

### As a Base Image

Use this as the base for your application image:

```dockerfile
FROM alecsavvy/postgres-embedded:latest

# Copy your application
COPY myapp /usr/local/bin/myapp

# Run your application (Postgres starts automatically)
CMD ["myapp"]
```

### Golang Example

```dockerfile
FROM alecsavvy/postgres-embedded:latest

# Copy your Go binary
COPY myapp /usr/local/bin/myapp

# Your app will run with Postgres already started
CMD ["myapp"]
```

In your Go code with `lib/pq`:

```go
package main

import (
    "database/sql"
    _ "github.com/lib/pq"
)

func main() {
    db, err := sql.Open("postgres", "host=/var/run/postgresql user=postgres dbname=postgres sslmode=disable")
    if err != nil {
        panic(err)
    }
    defer db.Close()
    
    // Your application logic here
}
```

Or with `pgx` (recommended for sqlc):

```go
package main

import (
    "context"
    "github.com/jackc/pgx/v5/pgxpool"
)

func main() {
    ctx := context.Background()
    pool, err := pgxpool.New(ctx, "postgres://postgres@/postgres?host=/var/run/postgresql")
    if err != nil {
        panic(err)
    }
    defer pool.Close()
    
    // Your application logic here
}
```

### Testing Locally

```bash
docker build -t myapp .
docker run --rm myapp
```

## How It Works

1. The image has PostgreSQL pre-installed and initialized
2. The entrypoint script starts Postgres in the background
3. Waits for Postgres to be ready
4. Runs your command (CMD)
5. Monitors both processes and handles shutdown gracefully

## Environment Variables

The following are pre-configured:

- `PGHOST=/var/run/postgresql`
- `PGUSER=postgres`
- `PGDATABASE=postgres`

This means commands like `psql` work without additional flags.

## Notes

- Postgres is configured for Unix socket connections only (no network listening)
- Uses lightweight settings suitable for development/testing
- `fsync` and `synchronous_commit` are disabled for speed
- Data is not persisted between container restarts

