# 🚀 Run the Whole Project: Start to Finish



Follow these steps to demonstrate the complete DevOps workflow (Jenkins -> Ansible -> Kubernetes -> HPA).

## 1. Start Infrastructure (Minikube)
Open a WSL terminal and start your local cluster.
```bash
# Start Minikube
minikube start

# Enable Metrics Server (CRITICAL for HPA autoscaling!)
minikube addons enable metrics-server

# Open tunnel (Required for LoadBalancer External IP) in a SEPARATE terminal
minikube tunnel
```

## 2. Seed Secrets (Manual Security Step)
Since we don't commit secrets to Git, you must seed them manually once.
```bash
# Run the seeding script (Git Bash / WSL)
chmod +x setup_secrets.sh
./setup_secrets.sh
```
> **⚠️ SECURITY WARNING:** `setup_secrets.sh` contains real passwords. It is added to `.gitignore` automatically. **Do not force add it to Git.** This file lives only on your local machine.

## 3. Trigger the Building & Deployment (Jenkins)
Now we trigger the CI/CD pipeline.

1.  **Make a change**: Edit a file or just an empty commit.
    ```bash
    git commit --allow-empty -m "Trigger pipeline"
    git push
    ```
2.  **Watch Jenkins**: Go to your Jenkins Dashboard.
    *   You should see the pipeline start.
    *   **Build**: Creates the docker image.
    *   **Test**: Runs `python manage.py test`.
    *   **Deploy**: Runs Ansible to apply `k8s/deployment.yaml`.

## 4. Verify Deployment
Once Jenkins finishes, check your cluster.

```bash
# Check if pods are running
kubectl get pods

# Check the autoscaler (Should be at 1 replica initially)
kubectl get hpa
```

## 5. Access the App via Ingress

**IMPORTANT**: We use Ingress for all access (not port-forward). This enables the Canary traffic splitting.

1.  **Start Minikube Tunnel** (in a separate terminal, keep it running):
    ```bash
    minikube tunnel
    ```
    (You may need to enter your password)

2.  **Clean up old LoadBalancer** (if it exists):
    ```bash
    kubectl delete svc infin8-app-service
    ```

3.  **Access the Application**:
    Open your browser to **[http://localhost](http://localhost)**
    
    *(No port number needed - Ingress uses port 80)*

## 6. Demonstrate Auto-Scaling (HPA)
Now, let's stress the system to show it scaling up.

1.  **Run the Load Script**:
    ```bash
    chmod +x load_test.sh
    ./load_test.sh <YOUR_APP_URL>
    ```
    *(Replace `<YOUR_APP_URL>` with the URL from Step 4)*

2.  **Watch it Scale**:
    In a new terminal:
    ```bash
    kubectl get hpa -w
    ```
3.  **Result**:
    *   As traffic hits, `TARGET` CPU % will go above 20%.
    *   `REPLICAS` will increase from **1 -> 5** automatically.
    *   This proves the "Self-Healing & Scaling" requirement!

## 7. Demonstrate Live Patching (Zero Downtime)
We will update the app while it's running. Users should see **ZERO errors**.

1.  **Ensure Minikube Tunnel is Running**:
    *   The `minikube tunnel` from Step 5 should still be active.
    *   If not, restart it in a separate terminal.

2.  **Start the Monitor**:
    In a new terminal, run the verification script:
    ```bash
    chmod +x verify_patching.sh
    ./verify_patching.sh http://localhost
    ```
    *You should see "SUCCESS (200 OK)" scrolling.*

3.  **Trigger an Update**:
    Make a small change to a file (e.g., change a text in `login_register.html`), commit, and push.
    ```bash
    git commit -am "Patch update"
    git push
    ```

4.  **Watch Magic Happen**:
    *   Jenkins will build and deploy.
    *   Kubernetes will start a **new pod**.
    *   It waits for the `readinessProbe` to pass.
    *   Only then does it kill the old pod.
    *   **Result**: Your "Monitor" script never stops printing "SUCCESS". Zero downtime!

## 8. Demonstrate Canary Deployment (AIOps)

**Concept**: Only **20%** of traffic goes to the new "Canary" version (Yellow Banner), managed by **NGINX Ingress**.

### Setup Access via Ingress

**IMPORTANT**: Stop any `kubectl port-forward` commands first. Ingress and port-forward are different access methods - use only one at a time.

1.  **Start Minikube Tunnel** (in a separate terminal, keep it running):
    ```bash
    minikube tunnel
    ```
    (This exposes the Ingress on `localhost:80`)

2.  **Remove Old LoadBalancer Service** (if it exists):
    ```bash
    kubectl delete svc infin8-app-service
    ```
    (This frees port 80 for the Ingress to use)

3.  **Verify Setup**:
    ```bash
    kubectl get svc
    ```
    You should see:
    - `infin8-stable` (ClusterIP)
    - `infin8-canary` (ClusterIP)
    - NO `infin8-app-service` (old LoadBalancer should be gone)

### Visual Verification

1.  **Open Browser**: `http://localhost/` (NO port number)
2.  **Refresh 10-15 times** rapidly
3.  **Expected Result**:
    - Most times: Normal page (Stable version)
    - ~20% of times: **Bright Yellow Banner** "⚠️ CANARY VERSION (v1.1) ⚠️" (Canary version)

### Why This Works

- **NGINX Ingress** uses the `canary-weight: "20"` annotation to route exactly 20% of requests to the Canary pods
- **Minikube Tunnel** exposes the Ingress Controller on your `localhost:80`
- The old LoadBalancer service would conflict with Ingress on port 80, so it must be removed

## 9. Verify ELK Stack & Logging
Verify that your application logs are flowing to Logstash and into Elasticsearch.

1.  **Generate Traffic**:
    Access the app a few times: `http://localhost/`

2.  **Access Kibana**:
    Open: `http://localhost/kibana`

3.  **Create Index Pattern**:
    *   Go to **Stack Management** > **Index Patterns**.
    *   Create pattern: `infin8-*`.
    *   Select `@timestamp`.

4.  **View Logs**:
    *   Go to **Discover**.
    *   Search for: `marketing` (or any text on your landing page).
    *   You should see logs with `type: "django"` and tags `["infin8", "logstash"]`.

## 10. Stop Everything
```bash
minikube stop
# Ctrl+C to stop minikube tunnel
# Ctrl+C to stop load_test.sh
```

## 8. Resetting / Wiping Data
If you need to clear the database to start fresh (e.g., to re-create the admin user), follow this EXACT order.

1.  **Stop the App First** (Releases the lock on the data):
    ```bash
    kubectl delete deployment mysql
    ```
    *Wait for the pod to disappear.*

2.  **Delete the Data**:
    ```bash
    kubectl delete pvc mysql-pv-claim
    ```

3.  **Restart**:
    Now when you deploy again (via Jenkins or manually), the database will be fresh.
    ```bash
    kubectl apply -f k8s/deployment.yaml
    ```
