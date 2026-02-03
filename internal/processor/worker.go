package processor

import (
	"context"
	"log"
	"os/exec"
	"time"

	"github.com/go-redis/redis/v8"
)

type Worker struct {
	rdb *redis.Client
}

func NewWorker(rdb *redis.Client) *Worker {
	return &Worker{
		rdb: rdb,
	}
}

// initiates the worker's processing loop
func (w *Worker) Start(ctx context.Context) {
	log.Println("Worker started, listening for control messages...")

	for {
		select {
		case <-ctx.Done():
			log.Println("Worker shutting down...")
			return
		default:
			w.checkChaos(ctx)
			w.processTask(ctx)

			time.Sleep(1 * time.Second)
		}
	}
}

func (w *Worker) checkChaos(ctx context.Context) {
	// Read from Redis Stream
	msgs, _ := w.rdb.XRead(ctx, &redis.XReadArgs{
		Streams: []string{"control_stream", "0"},
		Count:   1,
		Block:   100 * time.Millisecond,
	}).Result()

	for _, stream := range msgs {
		for _, msg := range stream.Messages {
			action := msg.Values["action"].(string)
			latencyMS := msg.Values["latency_ms"].(string)

			if action == "start" {
				w.injectLatency(latencyMS)
			} else if action == "stop" {
				w.clearChaos()
			}
		}
	}
}

func (w *Worker) injectLatency(ms string) {
	log.Printf("[CHAOS] Injecting %s ms latency...", ms)

	//tc' command modifies the pod's network namespace
	cmd := exec.Command("sudo", "tc", "qdisc", "add", "dev", "eth0", "root", "netem", "delay", ms+"ms")
	if err := cmd.Run(); err != nil {
		log.Printf("ERROR] Failed to inject chaos: %v", err)
	}
}

func (w *Worker) clearChaos() {
	log.Println("[RECOVERY] Clearing network chaos...")
	cmd := exec.Command("sudo", "tc", "qdisc", "del", "dev", "eth0", "root")
	_ = cmd.Run()
}

func (w *Worker) processTask(ctx context.Context) {
	log.Println("Processing task...")
}
