package main

import (
	"context"
	"os"

	"gitlab.com/piyush169/chaos-resilience/internal/processor"
	"gitlab.com/piyush169/chaos-resilience/internal/queue"
)

func main() {
	redisAddr := os.Getenv("REDIS_URL")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}
	rdb := queue.NewRedisClient(redisAddr)

	worker := processor.NewWorker(rdb)

	worker.Start(context.Background())
}
