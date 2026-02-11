package orchestrator

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes" // This fixes "undefined: kubernetes"
	"k8s.io/client-go/rest"
)

type Orchestrator struct {
	rdb       *redis.Client
	k8sClient *kubernetes.Clientset
}

func New(rdb *redis.Client) *Orchestrator {

	config, err := rest.InClusterConfig()
	if err != nil {

		panic(err.Error())
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	return &Orchestrator{
		rdb:       rdb,
		k8sClient: clientset,
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
	err := o.rdb.XAdd(c.Request.Context(), &redis.XAddArgs{
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

func (o *Orchestrator) GetClusterStatus(c *gin.Context) {

	queueLag, err := o.rdb.LLen(c.Request.Context(), "chaos_tasks").Result()
	if err != nil {
		queueLag = 0 // Fallback if Redis is empty
	}

	// 2. Fetch running pods from K8s API

	pods, err := o.k8sClient.CoreV1().Pods("default").List(c.Request.Context(), metav1.ListOptions{
		LabelSelector: "app=worker",
	})

	runningCount := 0
	if err == nil {
		for _, pod := range pods.Items {
			if pod.Status.Phase == "Running" {
				runningCount++
			}
		}
	}

	// 3. Determine status based on thresholds
	status := "healthy"
	if queueLag > 20 {
		status = "under_pressure"
	} else if runningCount > 5 {
		status = "scaling"
	}

	c.JSON(http.StatusOK, gin.H{
		"pods_running": runningCount,
		"queue_lag":    queueLag,
		"status":       status,
	})
}
