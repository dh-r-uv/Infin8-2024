# ELK Stack Monitoring - Infin8-2024

## Overview
ELK stack (Elasticsearch, Logstash, Kibana, Metricbeat) is **automatically deployed** by Jenkins to monitor your Kubernetes cluster. 

**What's monitored:**
- ✅ **Kubernetes pod metrics** (CPU, memory, network)
- ✅ **Container metrics** (Docker stats)
- ✅ **System metrics** (node resources)
- ❌ **Django application logs** (not configured - uses console logging only)

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (Minikube)               │
│                                                          │
│  ┌──────────────┐                                       │
│  │ Django Pods  │     (Console logging only)            │
│  │ (infin8-app) │                                       │
│  └──────────────┘                                       │
│                                                          │
│  ┌──────────────┐                                       │
│  │ Metricbeat   │──────────────────────────┐           │
│  │ (DaemonSet)  │    Pod/Container Metrics │           │
│  └──────────────┘                          ▼           │
│                                    ┌──────────────────┐ │
│                                    │  Elasticsearch   │ │
│                                    │  (StatefulSet)   │ │
│                                    └────────┬─────────┘ │
│                                             │           │
│                                       ┌─────▼──────┐   │
│                                       │   Kibana   │   │
│                                       │ (Service)  │   │
│                                       └─────┬──────┘   │
└─────────────────────────────────────────────┼──────────┘
                                              │
                                        ┌─────▼─────┐
                                        │  Ingress  │
                                        └───────────┘
                                              │
                                   http://localhost/kibana
```

**ELK Stack is automatically deployed during Jenkins builds.**

---

## Accessing Kibana

After any Jenkins build, Kibana is available at:

**http://localhost/kibana**

(Make sure `minikube tunnel` is running)

---

## Viewing Metrics - Quick Start

### Step 1: Create Metricbeat Index Pattern

1. Open Kibana: **http://localhost/kibana**
2. Go to **Stack Management** (gear icon in left sidebar)
3. Click **Index Patterns** → **Create index pattern**
4. **Index pattern name:** `metricbeat-*`
5. **Timestamp field:** `@timestamp`
6. Click **Create index pattern**

### Step 2: View Metrics in Discover

1. Click **☰** (hamburger menu) in Kibana
2. Go to **Analytics** → **Discover**
3. Select `metricbeat-*` from the index pattern dropdown (top left)
4. You'll see all pod/container metrics!

**Filter by:**
- `kubernetes.pod.name` - Specific pod metrics
- `kubernetes.namespace` - Namespace metrics
- `container.name` - Container-specific data

---

## Viewing Metrics

1. Go to **Discover** tab
2. Select `metricbeat-*` index pattern
3. Filter by fields like:
   - `kubernetes.pod.name`
   - `container.name`
   - `system.cpu.total.pct`

---

## Useful Queries

Search in **Discover** with these queries:

```
# High CPU pods
kubernetes.pod.cpu.usage.nanocores:>500000000

# High memory usage
kubernetes.pod.memory.usage.bytes:>500000000

# Pod restarts
kubernetes.container.restarts:>0

# Specific pod metrics
kubernetes.pod.name:"infin8-app*"

# Container errors
container.status:"error"
```

---

## Verifying ELK Stack Status

```bash
# Check all ELK pods
kubectl get pods | grep -E "elasticsearch|kibana|logstash|metricbeat"

# Check Elasticsearch health
kubectl exec elasticsearch-0 -- curl -s http://localhost:9200/_cluster/health?pretty

# View collected indices
kubectl exec elasticsearch-0 -- curl -s http://localhost:9200/_cat/indices?v

# Check Metricbeat is collecting
kubectl logs daemonset/metricbeat | head -20
```

---

## Troubleshooting

### Kibana shows 404 or 503
```bash
# Check Kibana pod status
kubectl get pods -l app=kibana

# Check ingress
kubectl get ingress kibana-ingress

# Restart if needed
kubectl rollout restart deployment/kibana
```

### No metrics showing
```bash
# Verify Metricbeat is running on all nodes
kubectl get pods -l app=metricbeat

# Check Metricbeat logs
kubectl logs daemonset/metricbeat

# Verify index exists
kubectl exec elasticsearch-0 -- curl http://localhost:9200/_cat/indices?v | grep metricbeat
```

### Dashboards not appearing
```bash
# Re-run dashboard setup
kubectl exec -it daemonset/metricbeat -- metricbeat setup --dashboards

# Wait a minute, then refresh Kibana Dashboard page
```

---

## What's NOT Included

❌ **Django application logs** - The Django app uses default console logging only. Application logs are visible via:
```bash
kubectl logs deployment/infin8-app
```

To add Django → ELK logging in the future, you would need to:
1. Install `python-logstash-async` in Dockerfile
2. Configure Django logging in `settings.py`
3. Rebuild and redeploy

---

## Summary

✅ **ELK stack automatically deployed** by Jenkins  
✅ **Metricbeat monitors** Kubernetes cluster  
✅ **Kibana accessible** at http://localhost/kibana  
✅ **Pre-built dashboards** for metrics visualization  
❌ **No Django app logs** in ELK (console only)

**Your Kubernetes cluster is being monitored!** 📊
