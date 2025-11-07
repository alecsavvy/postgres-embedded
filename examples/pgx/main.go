package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	ctx := context.Background()
	log.Println("Connecting to PostgreSQL with pgx...")

	pool, err := pgxpool.New(ctx, "postgres://postgres@/postgres?host=/var/run/postgresql")
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer pool.Close()

	// Test the connection
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	// Create a test table
	_, err = pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS test_table (
			id SERIAL PRIMARY KEY,
			message TEXT NOT NULL
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create table: %v", err)
	}

	// Insert a test row
	_, err = pool.Exec(ctx, "INSERT INTO test_table (message) VALUES ($1)", "Hello from pgx!")
	if err != nil {
		log.Fatalf("Failed to insert: %v", err)
	}

	// Query the test row
	var id int
	var message string
	err = pool.QueryRow(ctx, "SELECT id, message FROM test_table ORDER BY id DESC LIMIT 1").Scan(&id, &message)
	if err != nil {
		log.Fatalf("Failed to query: %v", err)
	}

	fmt.Printf("✓ Successfully connected with pgx\n")
	fmt.Printf("✓ Created table and inserted data\n")
	fmt.Printf("✓ Retrieved: id=%d, message=%s\n", id, message)
	log.Println("All tests passed!")
}

