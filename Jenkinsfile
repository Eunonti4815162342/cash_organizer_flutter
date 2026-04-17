pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'cash-organizer-frontend'
        DOCKER_CONTAINER = 'cash-organizer-frontend'
        API_URL = 'http://192.168.1.145:8085/api'
        REPO_URL = 'https://github.com/Eunonti4815162342/cash_organizer_flutter.git'
        GIT_BRANCH = 'master'
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                git branch: "${GIT_BRANCH}", credentialsId: 'cash_organizer', url: "${REPO_URL}"
                sh "echo '✓ Repository checked out'"
            }
        }

        stage('Verify Build Files') {
            steps {
                sh '''
                    echo "Checking Dockerfile and nginx.conf..."
                    test -f Dockerfile || (echo "ERROR: Dockerfile not found!" && exit 1)
                    test -f nginx.conf || (echo "ERROR: nginx.conf not found!" && exit 1)
                    test -f pubspec.yaml || (echo "ERROR: pubspec.yaml not found!" && exit 1)
                    echo "✓ All build files verified"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image: ${DOCKER_IMAGE}:latest"
                    docker build \
                        --network=host \
                        -t ${DOCKER_IMAGE}:latest \
                        -t ${DOCKER_IMAGE}:build-${BUILD_NUMBER} \
                        .
                    echo "✓ Docker image built successfully"
                    docker images ${DOCKER_IMAGE}
                '''
            }
        }

        stage('Stop & Remove Old Container') {
            steps {
                sh '''
                    echo "Stopping and removing old container..."
                    docker stop ${DOCKER_CONTAINER} 2>/dev/null || true
                    docker rm ${DOCKER_CONTAINER} 2>/dev/null || true
                    echo "✓ Old container removed"
                '''
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                    echo "Deploying new container..."
                    docker run -d \
                        --name ${DOCKER_CONTAINER} \
                        --network llama_net \
                        -p 8086:80 \
                        --health-cmd="curl -f http://localhost/health || exit 1" \
                        --health-interval=10s \
                        --health-timeout=5s \
                        --health-retries=3 \
                        --restart unless-stopped \
                        ${DOCKER_IMAGE}:latest

                    echo "✓ Container deployed with ID: $(docker ps -q -f name=${DOCKER_CONTAINER})"
                    sleep 3
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "Verifying deployment health..."
                    MAX_ATTEMPTS=10
                    ATTEMPT=0

                    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
                        if docker exec ${DOCKER_CONTAINER} curl -s http://localhost/health >/dev/null 2>&1; then
                            echo "✓ Frontend is healthy and responding"
                            docker exec ${DOCKER_CONTAINER} nginx -v 2>&1 | grep -i nginx
                            exit 0
                        fi
                        ATTEMPT=$((ATTEMPT + 1))
                        echo "Attempt $ATTEMPT/$MAX_ATTEMPTS - waiting for container to be ready..."
                        sleep 2
                    done

                    echo "✗ Deployment verification failed after $MAX_ATTEMPTS attempts"
                    echo "Container logs:"
                    docker logs ${DOCKER_CONTAINER}
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            sh '''
                echo "╔════════════════════════════════════════╗"
                echo "║  ✓ DEPLOYMENT SUCCESSFUL               ║"
                echo "╚════════════════════════════════════════╝"
                echo ""
                echo "Frontend URL: http://192.168.1.145:8086"
                echo "Backend API:  http://192.168.1.145:8085/api"
                echo ""
                echo "Container Status:"
                docker ps -f name=${DOCKER_CONTAINER} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            '''
        }
        failure {
            sh '''
                echo "╔════════════════════════════════════════╗"
                echo "║  ✗ DEPLOYMENT FAILED                   ║"
                echo "╚════════════════════════════════════════╝"
                echo ""
                echo "Container logs:"
                docker logs ${DOCKER_CONTAINER} || echo "Container not running"
                echo ""
                echo "Running containers:"
                docker ps -a --format "table {{.Names}}\t{{.Status}}"
            '''
        }
        always {
            cleanWs()
        }
    }
}
