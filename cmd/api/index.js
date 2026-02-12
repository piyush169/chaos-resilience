const express = require('express');
const redis = require('redis');
const app = express();
const port = 3000;

// Connect to Redis using the internal K8s DNS
const client = redis.createClient({
    url: 'redis://redis-service.default.svc.cluster.local:6379'
});

client.on('error', err => console.error('Redis Client Error', err));

app.use(express.json());

// Endpoint to trigger chaos
app.post('/trigger', async (req, res) => {
    const { count } = req.body;
    const taskCount = parseInt(count) || 5;

    try {
        if (!client.isOpen) await client.connect();
        
        const tasks = Array.from({ length: taskCount }, (_, i) => `chaos-task-${Date.now()}-${i}`);
        await client.lPush('chaos_tasks', tasks);
        
        res.status(200).send({
            message: `Successfully injected ${taskCount} chaos tasks.`,
            queue: 'chaos_tasks'
        });
    } catch (error) {
        res.status(500).send({ error: error.message });
    }
});

app.listen(port, () => console.log(`Chaos API listening on port ${port}`));