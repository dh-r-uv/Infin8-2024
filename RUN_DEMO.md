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

## 5. Access the App
Get the URL of the running application.

### Option A: Port Forwarding (Recommended)
This is the most reliable method on WSL.
```bash
kubectl port-forward svc/infin8-app-service 8081:80
```
Then open **[http://localhost:8081](http://localhost:8081)**.
*(Keep this terminal open)*

### Option B: Minikube Service URL
If port forwarding fails, try asking Minikube for the URL directly.
```bash
minikube service infin8-app-service --url
```

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

## 7. Stop Everything
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
