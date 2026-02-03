package orchestrator

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
)

type Orchestrator struct {
	rdb *redis.Client
}

func New(rdb *redis.Client) *Orchestrator {
	return &Orchestrator{
		rdb: rdb,
	}
}

func (o *Orchestrator) HandleChaos(c *gin.Context) {
	var req struct {
		Action    string `json:"action"` //start or stop
		LatencyMS int    `json:"latency_ms"`
	}

	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	//Send a control message to the Redis Stream that Workers are listening to
	err := o.rdb.XAdd(context.Background(), &redis.XAddArgs{
		Stream: "control_stream",
		Values: map[string]interface{}{
			"action":     req.Action,
			"latency_ms": req.LatencyMS,
		},
	}).Err()

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to enqueue chaos action"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Chaos signal sent to cluster"})
}

// GetClusterStatus fetches current metrics for your React Flow map
func (o *Orchestrator) GetClusterStatus(c *gin.Context) {
	// In a real setup, this would query the Kubernetes API
	// For now, we return mock data that your frontend can use
	c.JSON(http.StatusOK, gin.H{
		"pods_running": 2,
		"queue_lag":    15,
		"status":       "under_pressure",
	})
}
