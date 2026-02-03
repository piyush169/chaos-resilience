FROM golang:1.25-alpine AS builder
RUN apk add --no-cache git

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .

RUN go build -o /chaos-api cmd/api/main.go
RUN go build -o /chaos-worker cmd/worker/main.go

FROM alpine:latest
RUN apk add --no-cache iproute2 sudo

WORKDIR /root/

COPY --from=builder /chaos-api .
COPY --from=builder /chaos-worker .

EXPOSE 8080
CMD ["./chaos-api"]