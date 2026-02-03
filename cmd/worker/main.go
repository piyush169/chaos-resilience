package main

import (
	"context"

	"gitlab.com/piyush169/chaos-resilience/internal/processor"
	"gitlab.com/piyush169/chaos-resilience/internal/queue"
)

func main() {
	rdb := queue.NewRedisClient("localhost:6379")
	worker := processor.NewWorker(rdb)

	worker.Start(context.Background())
}
