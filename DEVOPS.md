# Infin8 DevOps Implementation Guide

This project successfully implements a complete DevOps framework to automate the SDLC.

## 1. CI/CD Pipeline (Jenkins)
**Tool**: Jenkins (Jenkinsfile)
**Location**: `Jenkinsfile` (Root)

The pipeline automates the following stages:
1.  **Checkout**: Pulls the latest code from Git.
2.  **Build**: Builds the Docker image (`dhruvk321/infin8`).
3.  **Test**: Runs automated Django tests inside the container (`python manage.py test`).
4.  **Push**: Pushes the built image to Docker Hub.
5.  **Deploy**: Triggers Ansible to deploy the application.

## 2. Infrastructure & Monitoring
**Tools**: Docker, Docker Compose, ELK Stack
**Location**: `docker-compose.yml`

The `docker-compose.yml` orchestrates the following services:
-   **MySQL**: Database (Version 8.0).
-   **Elasticsearch**: Search and analytics engine (Port 9200).
-   **Logstash**: Log processing pipeline (Ports 5044/5000).
-   **Kibana**: Data visualization dashboard (Port 5601).

### How to Run
```bash
docker-compose up -d
```
Access Kibana at [http://localhost:5601](http://localhost:5601) to view application logs.

## 3. Configuration Management
**Tool**: Ansible
**Location**: `ansible/`

-   **Inventory**: Defines target servers.
-   **Playbook**: `playbook.yaml` automates the installation of Docker and deployment of the application stack.

## 4. Orchestration (Kubernetes / Minikube)
**Tool**: Minikube (Local Kubernetes Cluster)
**Location**: `k8s/`

### Prerequisites
- **Minikube** installed (`minikube start` works).
- **kubectl** installed.

### Steps to Run on Minikube
1.  **Start Minikube**:
    ```bash
    minikube start
    ```

2.  **Deploy Application**:
    Apply the manifests to the cluster.
    ```bash
    kubectl apply -f k8s/deployment.yaml
    ```
    *This will create the MySQL database and the Infin8 application pods.*

3.  **Monitor Status**:
    Wait for the pods to be `Running`.
    ```bash
    kubectl get pods
    kubectl get svc
    ```

4.  **Access the Application**:
    Since the service is type `LoadBalancer`:

    *   **Option A (Recommended)**: Run a tunnel in a separate terminal to assign an External IP.
        ```bash
        minikube tunnel
        ```
# Infin8 DevOps Implementation Guide

This project successfully implements a complete DevOps framework to automate the SDLC.

## 1. CI/CD Pipeline (Jenkins)
**Tool**: Jenkins (Jenkinsfile)
**Location**: `Jenkinsfile` (Root)

The pipeline automates the following stages:
1.  **Checkout**: Pulls the latest code from Git.
2.  **Build**: Builds the Docker image (`dhruvk321/infin8`).
3.  **Test**: Runs automated Django tests inside the container (`python manage.py test`).
4.  **Push**: Pushes the built image to Docker Hub.
5.  **Deploy**: Triggers Ansible to deploy the application.

## 2. Infrastructure & Monitoring
**Tools**: Docker, Docker Compose, ELK Stack
**Location**: `docker-compose.yml`

The `docker-compose.yml` orchestrates the following services:
-   **MySQL**: Database (Version 8.0).
-   **Elasticsearch**: Search and analytics engine (Port 9200).
-   **Logstash**: Log processing pipeline (Ports 5044/5000).
-   **Kibana**: Data visualization dashboard (Port 5601).

### How to Run
```bash
docker-compose up -d
```
Access Kibana at [http://localhost:5601](http://localhost:5601) to view application logs.

## 3. Configuration Management
**Tool**: Ansible
**Location**: `ansible/`

-   **Inventory**: Defines target servers.
-   **Playbook**: `playbook.yaml` automates the installation of Docker and deployment of the application stack.

## 4. Orchestration (Kubernetes / Minikube)
**Tool**: Minikube (Local Kubernetes Cluster)
**Location**: `k8s/`

### Prerequisites
- **Minikube** installed (`minikube start` works).
- **kubectl** installed.

### Steps to Run on Minikube
1.  **Start Minikube**:
    ```bash
    minikube start
    ```

2.  **Deploy Application**:
    Apply the manifests to the cluster.
    ```bash
    kubectl apply -f k8s/deployment.yaml
    ```
    *This will create the MySQL database and the Infin8 application pods.*

3.  **Monitor Status**:
    Wait for the pods to be `Running`.
    ```bash
    kubectl get pods
    kubectl get svc
    ```

4.  **Access the Application**:
    Since the service is type `LoadBalancer`:

    *   **Option A (Recommended)**: Run a tunnel in a separate terminal to assign an External IP.
        ```bash
        minikube tunnel
        ```
        Then access via the `EXTERNAL-IP` shown in `kubectl get svc`.

    *   **Option B (Quick Access)**: Get the URL directly from Minikube.
        ```bash
        minikube service infin8-app-service --url
        ```
        **NOTE:** This command will likely block your terminal (keep running). **Do not close it.** Copy the URL it outputs and open it in your browser.

## 5. Development Setup (WSL)
Refer to `SETUP.md` for detailed instructions on running the project locally in a WSL Ubuntu environment.
