package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

func main() {
	log.Println("Connecting to PostgreSQL with lib/pq...")

	db, err := sql.Open("postgres", "host=/var/run/postgresql user=postgres dbname=postgres sslmode=disable")
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer db.Close()

	// Test the connection
	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	// Create a test table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS test_table (
			id SERIAL PRIMARY KEY,
			message TEXT NOT NULL
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create table: %v", err)
	}

	// Insert a test row
	_, err = db.Exec("INSERT INTO test_table (message) VALUES ($1)", "Hello from lib/pq!")
	if err != nil {
		log.Fatalf("Failed to insert: %v", err)
	}

	// Query the test row
	var id int
	var message string
	err = db.QueryRow("SELECT id, message FROM test_table ORDER BY id DESC LIMIT 1").Scan(&id, &message)
	if err != nil {
		log.Fatalf("Failed to query: %v", err)
	}

	fmt.Printf("✓ Successfully connected with lib/pq\n")
	fmt.Printf("✓ Created table and inserted data\n")
	fmt.Printf("✓ Retrieved: id=%d, message=%s\n", id, message)
	log.Println("All tests passed!")
}

