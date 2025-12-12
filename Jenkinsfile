pipeline {
    agent any

    environment {
        DOCKER_REGISTRY_USER = "${env.DOCKER_REGISTRY_USER ?: 'dhruvk321'}"
        DOCKER_IMAGE = "${DOCKER_REGISTRY_USER}/infin8"
        DOCKER_TAG = "build-${BUILD_NUMBER}"
        DOCKER_CREDS_ID = 'docker-credentials'
        KUBECONFIG = "/home/dhruv/.kube/config-jenkins"
        
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
