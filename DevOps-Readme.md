# DevOps Automation Framework - Infin8 2024

This project implements a complete **DevOps framework** to automate the Software Development Life Cycle (SDLC) for the `Infin8` application. It integrates Version Control, CI/CD, Containerization, Configuration Management, Orchestration, and Advanced Security/AIOps features.

---

## 🏗️ Architecture Overview

The pipeline ensures that **every Git commit** triggers an automated flow:
1.  **Code Commit** (GitHub)
2.  **Build & Test** (Jenkins)
3.  **Containerize** (Docker)
4.  **Deploy** (Ansible + Kubernetes)
5.  **Monitor & Scale** (HPA + AIOps Canary)

---

## 1. Version Control (Git & GitHub)
*   **Repo**: Hosted on GitHub.
*   **Workflow**: Incremental updates are pushed to the `main` branch.
*   **Trigger**: Jenkins polls the SCM (Source Code Management) for changes every minute and triggers the pipeline automatically when a change is detected.

---

## 2. CI/CD Automation (Jenkins)
We use a Declarative **Jenkins Pipeline** defined in `Jenkinsfile`.

### Pipeline Stages:
1.  **Checkout**: Pulls the latest code from GitHub.
2.  **Build & Test**: Installs dependencies and runs unit tests (verified via `manage.py test`).
3.  **Build Image**: Builds the Docker image (`dhruvk321/infin8:latest`) from the `Dockerfile`.
4.  **Push Image**: Authentication with DockerHub and pushing the new artifact.
5.  **Deploy**: Triggers the **Ansible Playbook** to update the Kubernetes cluster.

---

## 3. Containerization (Docker)
The application is containerized to ensure consistency across environments.
*   **File**: `Dockerfile`
*   **Base Image**: `python:3.10-slim` (Lightweight and secure).
*   **Optimization**: Uses layer caching to speed up builds.
*   **Registry**: Images are stored in public Docker Hub.

---

## 4. Configuration Management (Ansible)
Ansible is used to manage the Kubernetes deployment state in a **Modular** way.
*   **Playbook**: `ansible/playbook.yml`
*   **Roles Endpoint**: `ansible/roles/k8s_deploy`
*   **Tasks**:
    *   Applies Kubernetes Secrets (from Vault/Env).
    *   Applies Deployments (Stable & Canary).
    *   Applies Services & Auto-Scaling.
    *   **Force Rollout**: Executes `kubectl rollout restart` to ensure the latest image is pulled immediately (Live Patching).

---

## 5. Orchestration & Scaling (Kubernetes)
The application runs on a Kubernetes Cluster (Minikube).

### Components:
*   **Deployment**: `k8s/deployment.yaml`. Defines the `infin8-app` pods.
*   **Service**: `infin8-app-service` (LoadBalancer). Exposes the app to the outside world.
*   **Horizontal Pod Autoscaling (HPA)**: `k8s/hpa.yaml`.
    *   Automatically scales pods from **1 to 5** based on CPU utilization (>50%).
    *   Ensures High Availability during traffic spikes.
*   **Live Patching**:
    *   Uses `strategy: RollingUpdate` to update pods one by one.
    *   **Result**: Zero downtime during updates. The old version remains active until the new version is Ready.

---

## 🔒 6. Advanced Security: HashiCorp Vault
We implemented **Secure Storage** for sensitive credentials using HashiCorp Vault.
*   **Secrets Managed**: Database passwords, Secret Keys, Admin credentials.
*   **Integration**:
    *   The Django app (`settings.py`) connects to Vault at startup using the `hvac` library.
    *   It retrieves secrets dynamically, avoiding hardcoded passwords in the source code.
*   **Fallback**: If Vault is unreachable, it falls back to environment variables (for resilience).

---

## 🤖 7. Domain-Specific Project: AIOps (Canary Deployment)
**Bonus Feature (5 Marks)**

We implemented an **AIOps-style Canary Deployment** to reduce risk when introducing new features.

### Implementation:
1.  **Traffic Splitting**:
    *   **Stable Track**: The main deployment (`replicas: 1-5`).
    *   **Canary Track**: A separate deployment (`k8s/canary.yaml`, `replicas: 1`) running the same code but flagged as Canary.
    *   **Service Routing**: The Kubernetes Service routes traffic to *both*, allowing a small percentage (based on replica ratio) of users to see the new version.

2.  **Visual Verification**:
    *   **Feature**: A bright **Yellow Warning Banner** ("CANARY VERSION") appears only on the Canary pods.
    *   **Code**: `views.py` injects an `is_canary` flag based on the `CANARY_DEPLOYMENT` environment variable.

3.  **Automated Verification**:
    *   **Script**: `verify_canary.sh`
    *   **Function**: Continuously curls the application to detect statistical distribution of traffic between Stable (Blue/Cyan) and Canary (Yellow).

---

## 🚀 How to Validate the Framework

1.  **Make a Change**: Modify `Infin8/base/templates/login_register.html` (e.g., change title).
2.  **Push**: `git commit -am "Update title"; git push`.
3.  **Watch Jenkins**: The pipeline will start automatically.
4.  **Verification**:
    *   Wait for "deployment" stage to finish.
    *   Refresh the browser. You will see the change **without the server going down** (Rolling Update).
5.  **Test Canary**:
    *   Refresh multiple times. Occasionally you will see the **Canary Banner**.
    *   Run `./verify_canary.sh <URL>` to see the traffic split in real-time.
