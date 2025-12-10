# Automated Canary Deployment System

## Overview
This script demonstrates **true AIOps capabilities** by automating the entire canary deployment workflow - from deployment through monitoring to intelligent decision-making and execution.

## What It Does

### 1. 🚀 Deploy Canary
- Automatically deploys new version to canary pods
- Waits for rollout completion
- Verifies deployment success

### 2. 📊 Monitor Health (60 seconds)
Checks every 5 seconds:
- **HTTP Health**: Verifies application responds with 200 OK
- **Pod Readiness**: Ensures canary pods are ready and serving traffic
- **Error Tracking**: Calculates real-time error rate

### 3. 🤖 Intelligent Decision
**Auto-Promote** if:
- Error rate ≤ 10%
- All health checks passing

**Auto-Rollback** if:
- Error rate > 10%
- Pod failures detected

### 4. ✅ Auto-Execute
**Promotion Path:**
- Updates stable deployment to new version
- Gradually rolls out to 100% of users
- Zero manual intervention

**Rollback Path:**
- Reverts canary to old version
- Protects users from bad deployments
- Instant recovery

## Usage

### Basic Usage
```bash
chmod +x auto_canary.sh
./auto_canary.sh
```

### With Custom Images
```bash
./auto_canary.sh dhruvk321/infin8:v1.2 dhruvk321/infin8:v1.1
```

### Parameters
1. **Canary Image** (default: `dhruvk321/infin8:v1.1`) - New version to test
2. **Stable Image** (default: `dhruvk321/infin8:latest`) - Fallback version

## Demo Scenario

### Test 1: Successful Promotion
```bash
# 1. Make a good change (e.g., update banner text)
# 2. Build new image
docker build -t dhruvk321/infin8:v1.2 .
docker push dhruvk321/infin8:v1.2

# 3. Run automated deployment
./auto_canary.sh dhruvk321/infin8:v1.2

# Expected: ✅ Auto-promotes to stable after 60s
```

### Test 2: Automatic Rollback
```bash
# 1. Introduce a bug (e.g., invalid Python syntax)
# 2. Build broken image
docker build -t dhruvk321/infin8:broken .
docker push dhruvk321/infin8:broken

# 3. Run automated deployment
./auto_canary.sh dhruvk321/infin8:broken

# Expected: ❌ Auto-rolls back when errors detected
```

## How It Works

### Monitoring Loop
```
Every 5 seconds for 60 seconds:
├─ HTTP Request → localhost/login/
├─ Check Response Code (200 = good)
├─ Query Pod Status (Ready/Total)
├─ Calculate Error Rate
└─ Display Real-time Status
```

### Decision Logic
```python
if error_rate <= 10%:
    promote_to_stable()  # 100% rollout
else:
    rollback_canary()    # Revert to old version
```

### Output Example
```
[5s/60s] ✅ HTTP:200 Ready:1/1 | Error Rate: 0% | Status: HEALTHY | Remaining: 55s
[10s/60s] ✅ HTTP:200 Ready:1/1 | Error Rate: 0% | Status: HEALTHY | Remaining: 50s
...
[60s/60s] ✅ HTTP:200 Ready:1/1 | Error Rate: 0% | Status: HEALTHY | Remaining: 0s

📊 Monitoring Complete
Total Checks: 12
Successful: 12
Failed: 0
Error Rate: 0%

✅ DECISION: PROMOTE TO STABLE
🚀 Promoting Canary to Stable...
🎉 SUCCESS! New version promoted to 100% of users
```

## Integration with Jenkins

Add to `Jenkinsfile` to automate on every commit:

```groovy
stage('Canary Deployment') {
    steps {
        sh '''
            ./auto_canary.sh ${DOCKER_IMAGE}:${BUILD_NUMBER}
        '''
    }
}
```

## Why This is AIOps

✅ **Automated Monitoring**: Continuous health checks without human intervention  
✅ **Intelligent Decision**: AI-like logic based on metrics  
✅ **Self-Healing**: Automatic rollback on failure  
✅ **Production-Grade**: Used by Netflix, Google, Amazon  
✅ **Risk Reduction**: Limits blast radius to 20% initially  

## Architecture

```
┌─────────────────────────────────────────┐
│ auto_canary.sh                          │
├─────────────────────────────────────────┤
│ 1. Deploy Canary (20% traffic)          │
│    └─ kubectl set image deployment/...  │
│                                          │
│ 2. Monitor (60s)                        │
│    ├─ HTTP Health Check                 │
│    └─ Pod Readiness Check                │
│                                          │
│ 3. Analyze                              │
│    └─ error_rate = failed / total       │
│                                          │
│ 4. Decide                               │
│    ├─ If error_rate ≤ 10% → PROMOTE    │
│    └─ Else → ROLLBACK                  │
│                                          │
│ 5. Execute                              │
│    ├─ Promote: Update stable to new     │
│    └─ Rollback: Revert canary to old    │
└─────────────────────────────────────────┘
```

## Configuration

Edit these variables in the script:

```bash
MONITOR_DURATION=60   # Monitoring period (seconds)
CHECK_INTERVAL=5      # Check frequency (seconds)
ERROR_THRESHOLD=10    # Max error rate % before rollback
```

## Real-World Value

In production environments, this automation:
- **Prevents Outages**: Catches bad deployments before 100% rollout
- **Reduces MTTR**: Mean Time To Recovery drops from hours to seconds
- **Increases Velocity**: Teams deploy more confidently, more frequently
- **Saves Money**: Prevents revenue loss from failed deployments

## Comparison to Manual Process

| Task | Manual | Automated |
|------|--------|-----------|
| Deploy Canary | 5 min | Instant |
| Monitor Health | 30 min (human watching) | 60s (script) |
| Decision Making | 10 min (team meeting) | Instant |
| Execute Action | 5 min | Instant |
| **Total** | **50 minutes** | **~2 minutes** |

Plus: Automated process runs 24/7, never gets tired, makes consistent decisions!
