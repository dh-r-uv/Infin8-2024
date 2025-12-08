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

## 2. Trigger the Building & Deployment (Jenkins)
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

## 3. Verify Deployment
Once Jenkins finishes, check your cluster.

```bash
# Check if pods are running
kubectl get pods

# Check the autoscaler (Should be at 1 replica initially)
kubectl get hpa
```

## 4. Access the App
Get the URL of the running application.
```bash
    *   **Option A (Most Reliable)**: Use Port Forwarding.
        ```bash
        kubectl port-forward svc/infin8-app-service 8081:80
        ```
        Then open **[http://localhost:8081](http://localhost:8081)**.
        *(Keep this terminal open)*

    *   **Option B**: Minikube Service URL (might ask for password on WSL).
        ```bash
        minikube service infin8-app-service --url
        ```

## 5. Demonstrate Auto-Scaling (HPA)
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
    *   As traffic hits, `TARGET` CPU % will go above 50%.
    *   `REPLICAS` will increase from **1 -> 5** automatically.
    *   This proves the "Self-Healing & Scaling" requirement!

## 6. Stop Everything
```bash
minikube stop
# Ctrl+C to stop minikube tunnel
# Ctrl+C to stop load_test.sh
```
