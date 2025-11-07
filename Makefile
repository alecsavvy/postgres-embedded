.PHONY: build test test-libpq test-pgx clean

# Build the base postgres-embedded image
build:
	@echo "Building postgres-embedded base image..."
	docker build -t alecsavvy/postgres-embedded:latest .
	@echo "✓ Base image built successfully"

# Test both examples
test: build test-libpq test-pgx
	@echo ""
	@echo "================================"
	@echo "✓ All tests passed successfully!"
	@echo "================================"

# Test lib/pq example
test-libpq:
	@echo ""
	@echo "Building lib/pq example..."
	docker build -t test-libpq examples/libpq
	@echo "Running lib/pq test..."
	docker run --rm test-libpq
	@echo "✓ lib/pq test passed"

# Test pgx example
test-pgx:
	@echo ""
	@echo "Building pgx example..."
	docker build -t test-pgx examples/pgx
	@echo "Running pgx test..."
	docker run --rm test-pgx
	@echo "✓ pgx test passed"

# Clean up test images
clean:
	@echo "Cleaning up test images..."
	-docker rmi test-libpq test-pgx alecsavvy/postgres-embedded:latest 2>/dev/null || true
	@echo "✓ Cleanup complete"

