pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'dhruvk321/infin8'
        DOCKER_TAG = "latest"
        // Credentials ID as provided by the user
        DOCKER_CREDS_ID = 'docker-credentials' 
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
                    echo 'Building Docker image...'
                    // Build the image using the Dockerfile in current directory
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    echo 'Running Tests...'
                    // Run tests inside the container using SQLite to avoid MySQL connection dependency
                    sh """
                    docker run --rm \
                    -e USE_SQLITE=True \
                    -e EMAIL_HOST_USER=dummy@example.com \
                    -e EMAIL_HOST_PASSWORD=dummy \
                    ${DOCKER_IMAGE}:${DOCKER_TAG} \
                    python manage.py test
                    """
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    echo 'Pushing Docker image to registry...'
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo 'Deploying to Minikube via Ansible...'
                    // Assumes Jenkins can run ansible directly or via a shell
                    sh "ansible-playbook ansible/k8s-playbook.yaml"
                }
            }
        }
    }
}
