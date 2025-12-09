#!/bin/bash

# setup_secrets.sh
# Run this ONCE to securely seed your Kubernetes Cluster with secrets.
# This prevents sensitive data from being stored in Git (k8s/secrets.yaml).

echo "🔐 Seeding Kubernetes Secrets..."

# Delete existing secret if it exists (to allow updates)
kubectl delete secret infin8-secrets --ignore-not-found

# Create the secret manually
kubectl create secret generic infin8-secrets \
    --from-literal=mysql-root-password=root \
    --from-literal=mysql-password=root \
    --from-literal=mysql-user=root \
    --from-literal=mysql-db=Infin8 \
    --from-literal=email-user=dummy@example.com \
    --from-literal=email-password=dummy

echo "✅ Secrets created successfully!"
echo "Now you can run the Jenkins pipeline."
