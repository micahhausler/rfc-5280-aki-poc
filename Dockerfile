# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY go.mod ./
COPY main.go .
RUN go build -o server .

# Final stage
FROM alpine:latest

WORKDIR /app
COPY --from=builder /app/server .

# Expose the port
EXPOSE 443

# Set the server as the entrypoint and default arguments
ENTRYPOINT ["/app/server"]
CMD ["-cert", "/app/certs/apiserver.crt", "-key", "/app/certs/apiserver.key"] 