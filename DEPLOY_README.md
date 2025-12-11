# Infin8 DevOps Deployment Guide

This project implements a complete DevOps framework to automate the Software Development Life Cycle (SDLC) using a comprehensive suite of tools for Version Control, CI/CD, Containerization, Orchestration, Configuration Management, and Monitoring.

## 🚀 DevOps Framework Overview

The infrastructure relies on the following core technologies:

| Category | Tool | Usage |
|----------|------|-------|
| **Version Control** | **Git & GitHub** | Source code management and collaboration. |
| **CI/CD Automation** | **Jenkins** | Automated pipelines for building, testing, and deploying. |
| **Containerization** | **Docker** | Packaging application and dependencies into portable images. |
| **Configuration Mgmt** | **Ansible** | Automating deployment commands and Kubernetes resource management. |
| **Orchestration** | **Kubernetes (K8s)** | Managing container deployment, scaling, and networking (Minikube). |
| **Monitoring & Logging** | **ELK Stack** | Elasticsearch, Kibana, and Metricbeat for observability. |

---

## 🔄 1. CI/CD Automation (Jenkins)

The project uses a **Jenkins Pipeline** (`Jenkinsfile`) to automate the delivery process.

### **Pipeline Workflow**
Triggers on: **Incremental updates (Git Push / PollSCM)**.

1.  **Checkout**: Fetches the latest code from the GitHub repository.
2.  **Build Docker Image**: Builds the `infin8` application image from the `Dockerfile`.
3.  **Test**: Runs automated unit tests inside a temporary container to ensure code quality.
4.  **Push to Registry**: Pushes the successful image to **Docker Hub** (`dhruvk321/infin8:latest`).
5.  **Deploy**: Triggers an **Ansible Playbook** to apply Kubernetes manifests.

---

## 🐳 2. Containerization (Docker)

*   **Custom Image**: The application is containerized using a `Dockerfile` based on Python.
*   **Docker Compose**: Used for local development and defining dependent services like MySQL, Vault, and the ELK stack (`docker-compose.yml`).

---

## ☸️ 3. Orchestration & Scaling (Kubernetes)

The application is deployed on a Kubernetes cluster (Minikube).

### **Core Components**
*   **Deployments**:
    *   `infin8-app`: The main stable application deployment.
    *   `mysql`: Database deployment with Persistent Volume Claims (PVC).
*   **Services**: `ClusterIP` services expose the app and database within the cluster.
*   **Ingress**: **NGINX Ingress Controller** routes external traffic to the services.

### **Advanced Features**

#### **🔹 Canary Deployment Strategy**
We utilize a base application style deployment alongside a **Canary** setup to test new features safely.
*   **Canary Deployment**: `k8s/canary.yaml` deploys a subset of pods with the new version.
*   **Traffic Splitting**: The Ingress is configured with `nginx.ingress.kubernetes.io/canary-weight: "20"`, routing **20% of traffic** to the canary version (`infin8-canary`) and 80% to the stable version (`infin8-stable`).

#### **🔹 Horizontal Pod Autoscaling (HPA)**
*   **Dynamic Scaling**: The `infin8-hpa` automatically scales the number of pods based on CPU utilization.
    *   **Trigger**: >20% CPU utilization.
    *   **Range**: Min 1 replica, Max 5 replicas.

#### **🔹 Live Patching**
*   **Rolling Updates**: The `infin8-app` deployment uses a `RollingUpdate` strategy (`maxSurge: 1`, `maxUnavailable: 0`) to ensure **zero downtime** during updates. New pods are started and verified before old pods are terminated.

---

## 🛠️ 4. Configuration Management (Ansible)

Ansible is used to decouple the deployment logic from the CI/CD server, promoting disjoint configuration management.
*   **Playbook**: `ansible/k8s-playbook.yaml`
*   **Roles**: Modular design using roles (e.g., `k8s_deploy`) to handle specific deployment tasks.

---

## 📊 5. Monitoring & Logging (ELK Stack)

The system uses the **ELK Stack** (Elasticsearch, Logstash/Metricbeat, Kibana) for full observability.

*   **Elasticsearch**: Stores logs and metrics.
*   **Kibana**: Visualizes data through interactive dashboards.
*   **Metricbeat/Logstash**:
    *   **Metricbeat** (K8s): Deployed as a **DaemonSet** on Kubernetes to collect system and container metrics (CPU, Memory, Network) from every node.
    *   **Logstash** (Local/Docker): Configured to process application logs.

**Accessing Dashboards**:
*   Kibana is accessible via Ingress at `/kibana` (e.g., `http://<minikube-ip>/kibana`).

---

## 🔐 6. Security & Secrets Management

*   **HashiCorp Vault**: Integrated for secure storage of sensitive credentials (usernames, passwords, API keys).
*   **K8s Secrets**: Kubernetes Secrets (`infin8-secrets`) are used to inject sensitive environment variables (DB credentials, Django secret keys) securely into pods, ensuring no hardcoded secrets exist in the source code.

---

## 🚀 How to Validate the Setup

1.  **Push Changes**: Commit code to GitHub.
2.  **Jenkins Build**: Watch the pipeline Build -> Test -> Push -> Deploy.
3.  **Access App**: Visit `http://<minikube-ip>/` to see the application.
    *   Refresh to potentially see Canary version (20% chance).
4.  **Check Scaling**: Run a load test and watch `kubectl get hpa` to see replica count increase.
5.  **View Logs**: Open Kibana to monitor application activity and metrics.
