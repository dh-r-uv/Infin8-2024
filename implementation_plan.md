# Automated Canary Deployment via Jenkins - Implementation Plan (Revised)

## Goal

Integrate automated canary deployment into Jenkins CI/CD while **maintaining Ansible as the Configuration Management tool**.

Workflow:
- **First deployment**: Ansible applies all Kubernetes manifests to stable
- **Subsequent deployments**: Ansible deploys canary → monitoring script validates → auto-promotes or rolls back

## Background

Currently:
- Jenkins uses Ansible to deploy Kubernetes resources
- Ansible role `k8s_deploy` applies manifests and restarts deployments
- [auto_canary.sh](file:///c:/Users/dhruv/OneDrive%20-%20iiit-b/Desktop/sem7/SE/endsem-project/New%20folder/Infin8-2024/auto_canary.sh) exists for manual canary testing

**Why keep Ansible?**
- ✅ Demonstrates **Configuration Management** (required DevOps component)
- ✅ Provides idempotent infrastructure-as-code
- ✅ Separates deployment logic from CI/CD orchestration
- ✅ Easier to maintain and audit than pure shell scripts

---

## Proposed Changes

### Ansible Roles

#### [NEW] ansible/roles/canary_deploy/tasks/main.yml

Create a new Ansible role for intelligent canary deployment:

```yaml
---
- name: Check if stable deployment exists
  ansible.builtin.shell: kubectl get deployment infin8-app
  register: stable_exists
  ignore_errors: true
  changed_when: false

- name: First Deployment - Apply all manifests to stable
  block:
    - name: Apply deployment manifests
      ansible.builtin.shell: kubectl apply -f k8s/deployment.yaml
      args:
        chdir: "{{ playbook_dir }}/.."
    
    - name: Apply HPA
      ansible.builtin.shell: kubectl apply -f k8s/hpa.yaml
      args:
        chdir: "{{ playbook_dir }}/.."
    
    - name: Apply Ingress
      ansible.builtin.shell: kubectl apply -f k8s/ingress.yaml
      args:
        chdir: "{{ playbook_dir }}/.."
    
    - name: Set stable image to new version
      ansible.builtin.shell: "kubectl set image deployment/infin8-app infin8-app={{ new_image }}"
      
    - name: Wait for stable rollout
      ansible.builtin.shell: kubectl rollout status deployment/infin8-app --timeout=300s
      
  when: stable_exists.rc != 0

- name: Subsequent Deployment - Canary workflow
  block:
    - name: Apply canary deployment manifest
      ansible.builtin.shell: kubectl apply -f k8s/canary.yaml
      args:
        chdir: "{{ playbook_dir }}/.."
    
    - name: Update canary image
      ansible.builtin.shell: "kubectl set image deployment/infin8-canary infin8-app={{ new_image }}"
    
    - name: Wait for canary to be ready
      ansible.builtin.shell: kubectl rollout status deployment/infin8-canary --timeout=300s
    
    - name: Run automated canary validation
      ansible.builtin.shell: "./auto_canary.sh {{ new_image }} {{ stable_image }}"
      args:
        chdir: "{{ playbook_dir }}/.."
      register: canary_result
      
    - name: Report canary result
      debug:
        msg: "{{ canary_result.stdout }}"
        
  when: stable_exists.rc == 0
```

---

#### [MODIFY] ansible/k8s-playbook.yaml

Update to use the new canary deployment role:

```yaml
---
- name: Intelligent Canary Deployment to Kubernetes
  hosts: localhost
  connection: local
  gather_facts: false
  vars:
    new_image: "{{ lookup('env', 'NEW_IMAGE') }}"
    stable_image: "{{ lookup('env', 'STABLE_IMAGE') | default('dhruvk321/infin8:latest', true) }}"
  roles:
    - canary_deploy
```

---

### Jenkins Pipeline

#### [MODIFY] [Jenkinsfile](file:///c:/Users/dhruv/OneDrive%20-%20iiit-b/Desktop/sem7/SE/endsem-project/New%20folder/Infin8-2024/Jenkinsfile)

Update to use versioned builds and pass image info to Ansible:

**Changes:**
1. Tag images with `build-${BUILD_NUMBER}` for traceability
2. Also tag as `latest` for backward compatibility
3. Set environment variables for Ansible
4. Deploy via Ansible (which now has intelligent canary logic)

```groovy
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'dhruvk321/infin8'
        DOCKER_TAG = "build-${BUILD_NUMBER}"
        DOCKER_CREDS_ID = 'docker-credentials'
        // These will be used by Ansible
        NEW_IMAGE = "${DOCKER_IMAGE}:build-${BUILD_NUMBER}"
        STABLE_IMAGE = "${DOCKER_IMAGE}:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${NEW_IMAGE}"
                    sh "docker build -t ${NEW_IMAGE} ."
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    echo 'Running Tests...'
                    sh """
                    docker run --rm \\
                    -e USE_SQLITE=True \\
                    -e EMAIL_HOST_USER=dummy@example.com \\
                    -e EMAIL_HOST_PASSWORD=dummy \\
                    ${NEW_IMAGE} \\
                    python manage.py test
                    """
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    echo "Pushing images: ${NEW_IMAGE} and ${DOCKER_IMAGE}:latest"
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        sh "docker push ${NEW_IMAGE}"
                        // Also tag and push as 'latest'
                        sh "docker tag ${NEW_IMAGE} ${DOCKER_IMAGE}:latest"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }

        stage('Intelligent Deploy via Ansible') {
            steps {
                script {
                    echo 'Deploying via Ansible with intelligent canary logic...'
                    sh """
                    export NEW_IMAGE=${NEW_IMAGE}
                    export STABLE_IMAGE=${STABLE_IMAGE}
                    ansible-playbook ansible/k8s-playbook.yaml
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Deployment successful! Image: ${NEW_IMAGE}"
        }
        failure {
            echo "❌ Deployment failed - check logs"
        }
    }
}
```

---

### Supporting Scripts

#### [MODIFY] [auto_canary.sh](file:///c:/Users/dhruv/OneDrive%20-%20iiit-b/Desktop/sem7/SE/endsem-project/New%20folder/Infin8-2024/auto_canary.sh)

Add proper exit codes for CI/CD integration:

```bash
# At the end of the script (after line 173):

# Exit with appropriate code
if [ "$DECISION" = "PROMOTE" ]; then
    exit 0  # Success
else
    exit 1  # Rollback means deployment failed
fi
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Git Push                                │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│                    Jenkins Pipeline                          │
│  1. Build image as build-${BUILD_NUMBER}                    │
│  2. Run tests                                                 │
│  3. Push to Docker Hub (versioned + latest)                  │
│  4. Trigger Ansible playbook                                 │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│             Ansible (Configuration Management)               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Check: Does stable deployment exist?                 │   │
│  └──────────┬─────────────────────────┬─────────────────┘   │
│             │                          │                      │
│        NO (First)                 YES (Subsequent)            │
│             │                          │                      │
│  ┌──────────▼──────────┐    ┌─────────▼──────────┐         │
│  │ Apply all manifests │    │ Deploy to canary    │         │
│  │ to stable           │    │ Run auto_canary.sh  │         │
│  │ Set new image       │    │ Monitor & decide    │         │
│  └─────────────────────┘    └──────┬──────────────┘         │
│                                     │                         │
│                          ┌──────────┴──────────┐             │
│                     Healthy?            Unhealthy?            │
│                          │                     │              │
│                   ┌──────▼──────┐      ┌──────▼──────┐      │
│                   │ Promote to  │      │ Rollback    │      │
│                   │ stable (100%)│      │ Exit 1      │      │
│                   │ Exit 0      │      └─────────────┘      │
│                   └─────────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Benefits of This Approach

✅ **Maintains Ansible**: Configuration Management requirement satisfied  
✅ **Progressive Delivery**: Industry-standard canary deployment  
✅ **Automated Validation**: No manual intervention needed  
✅ **Version Tracking**: Build numbers for full traceability  
✅ **Fail-Safe**: Bad deployments automatically roll back  
✅ **Separation of Concerns**: Jenkins (CI/CD) → Ansible (Config Mgmt) → Script (Logic)

---

## Verification Plan

### Test Scenario 1: First Deployment
```bash
# Clean slate
kubectl delete deployment infin8-app infin8-canary 2>/dev/null || true

# Push code change
git commit -am "Test first deployment" && git push

# Expected: Ansible deploys directly to stable
kubectl get deployments
# Should see infin8-app with new image
```

### Test Scenario 2: Healthy Canary
```bash
# Make visible change (e.g., update title in template)
git commit -am "Update feature" && git push

# Expected: Canary deployed → monitored → promoted
# Both stable and canary should end up with new version
```

### Test Scenario 3: Unhealthy Canary
```bash
# Introduce bug (e.g., syntax error)
git commit -am "Buggy code" && git push

# Expected: Canary deployed → detected unhealthy → rolled back
# Stable remains on working version
# Jenkins build marked as FAILED
```

---

## User Review Required

> [!IMPORTANT]
> **Ansible Integration Maintained**
> 
> This approach keeps Ansible as the core Configuration Management tool, which is critical for demonstrating complete DevOps framework.

> [!WARNING]
> **Prerequisites**
> 
> 1. Jenkins needs `ansible` installed
> 2. Jenkins needs [kubectl](file:///c:/Users/dhruv/OneDrive%20-%20iiit-b/Desktop/sem7/SE/endsem-project/New%20folder/Infin8-2024/kubectl) configured for cluster access
> 3. [auto_canary.sh](file:///c:/Users/dhruv/OneDrive%20-%20iiit-b/Desktop/sem7/SE/endsem-project/New%20folder/Infin8-2024/auto_canary.sh) must be executable: `chmod +x auto_canary.sh`

---

## Summary

This revised approach:
- ✅ Keeps Ansible for Configuration Management
- ✅ Adds intelligent canary deployment logic
- ✅ Fully automates the deployment pipeline
- ✅ Demonstrates production-grade DevOps practices
