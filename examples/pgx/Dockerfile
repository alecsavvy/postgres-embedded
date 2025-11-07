FROM golang:1.21-alpine AS builder

WORKDIR /build
COPY go.mod go.sum* ./
RUN go mod download
COPY main.go ./
RUN CGO_ENABLED=0 go build -o app main.go

FROM alecsavvy/postgres-embedded:latest

COPY --from=builder /build/app /usr/local/bin/app

CMD ["app"]

