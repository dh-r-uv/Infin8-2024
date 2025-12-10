# ELK Stack Monitoring - Infin8-2024

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (Minikube)               │
│                                                          │
│  ┌──────────────┐                                       │
│  │ Django Pods  │─────┐                                 │
│  │ (infin8-app) │     │ Logs (TCP:5000)                 │
│  └──────────────┘     │                                 │
│                       ▼                                 │
│                ┌─────────────┐     ┌──────────────────┐ │
│                │  Logstash   │────▶│  Elasticsearch   │ │
│                │  (Service)  │     │  (StatefulSet)   │ │
│                └─────────────┘     └────────┬─────────┘ │
│                                              │           │
│  ┌──────────────┐                           │           │
│  │ Metricbeat   │──────────────────────────▶│           │
│  │ (DaemonSet)  │    Pod/Container Metrics  │           │
│  └──────────────┘                           ▼           │
│                                       ┌──────────────┐  │
│                                       │   Kibana     │  │
│                                       │  (Service)   │  │
│                                       └──────┬───────┘  │
└──────────────────────────────────────────────┼──────────┘
                                               │
                                         ┌─────▼─────┐
                                         │  Ingress  │
                                         └───────────┘
                                               │
                                    http://localhost/kibana
```

**ELK Stack is automatically deployed to Kubernetes when you run Jenkins build.**

---

## Accessing Kibana Dashboard

After Jenkins successfully deploys your application, access Kibana:

### Method 1: Via Ingress (Recommended)
```bash
# Access Kibana through Ingress
http://localhost/kibana
```

### Method 2: Port Forward
```bash
# Forward Kibana port to localhost
kubectl port-forward svc/kibana 5601:5601

# Then access
http://localhost:5601
```

---

## Viewing Logs

### 1. Create Index Patterns (First Time Only)

1. Open Kibana: http://localhost/kibana
2. Go to **Stack Management** → **Index Patterns**
3. Create pattern: `infin8-*`
4. Select timestamp field: `@timestamp`
5. Click **Create index pattern**

### 2. View Application Logs

1. Go to **Discover** tab
2. Select `infin8-*` index pattern
3. You'll see all Django application logs!

**Common Filters:**
```
level:ERROR              # All errors
level:WARNING            # Warnings
type:django              # Application logs
type:canary              # Canary deployment logs
```

---

## Viewing Kubernetes Metrics

### 1. Create Metricbeat Index Pattern

1. Go to **Stack Management** → **Index Patterns**
2. Create pattern: `metricbeat-*`
3. Select timestamp field: `@timestamp`

### 2. View Metrics Dashboard

1. Go to **Dashboard** tab
2. Select **[Metricbeat Docker] Overview** or **[Metricbeat Kubernetes] Overview**
3. View:
   - Pod CPU/Memory usage
   - Container metrics
   - Network I/O
   - Disk usage

---

## Monitoring Canary Deployments

Track canary deployment events in Kibana:

```
# Search for canary logs
type:canary

# Filter by deployment status
type:canary AND message:"promoted"
type:canary AND message:"rollback"
```

---

## Useful Kibana Queries

```
# Application errors in last 24 hours
level:ERROR AND @timestamp:[now-24h TO now]

# HTTP 500 errors
status_code:500

# Pods with high memory
kubernetes.pod.memory.usage.bytes:>500000000

# Container restarts
kubernetes.container.restarts:>0
```

---

## Verifying ELK Stack Status

```bash
# Check all ELK pods are running
kubectl get pods -l app=elasticsearch
kubectl get pods -l app=logstash
kubectl get pods -l app=kibana

# Check Elasticsearch health
kubectl exec -it elasticsearch-0 -- curl http://localhost:9200/_cluster/health?pretty

# View logs being processed
kubectl logs deployment/logstash -f
```

---

## Troubleshooting

### Kibana not accessible
```bash
# Check Kibana pod status
kubectl get pods -l app=kibana

# Check ingress
kubectl get ingress

# Restart if needed
kubectl rollout restart deployment/kibana
```

### No logs appearing
```bash
# Verify Logstash is receiving logs
kubectl logs deployment/logstash | grep "input"

# Check Elasticsearch indices
kubectl exec -it elasticsearch-0 -- curl http://localhost:9200/_cat/indices?v

# Send test log
kubectl run -i --rm logtest --image=busybox --restart=Never -- \
  sh -c "echo '{\"message\":\"test\",\"type\":\"django\"}' | nc logstash 5000"
```

---

**ELK stack automatically monitors your application after every Jenkins deployment!** 📊
