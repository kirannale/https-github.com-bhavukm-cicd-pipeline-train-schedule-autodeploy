pipeline {
    agent any

    environment {
        IMAGE_NAME = "abstergo-website"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        WORKSPACE_PATH = "AWS_Projects/Project2"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
                script {
                    if (isUnix()) {
                        sh 'git submodule update --init --recursive'
                    } else {
                        bat 'git submodule update --init --recursive'
                    }
                }
            }
        }

        stage('Verify Files') {
            steps {
                echo 'Verifying application files...'
                script {
                    dir("${WORKSPACE_PATH}") {
                        if (isUnix()) {
                            sh 'ls -la app/website/ || echo "Files not found"'
                            sh 'test -f app/website/index.php && echo "✓ Application files present" || exit 1'
                        } else {
                            bat 'dir app\\website\\'
                            bat 'if exist app\\website\\index.php (echo Application files present) else (exit 1)'
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    dir("${WORKSPACE_PATH}") {
                        // Get Docker Hub credentials if available
                        def dockerhubUsername = env.DOCKERHUB_USERNAME ?: 'local'

                        if (isUnix()) {
                            sh """
                                docker build -t ${dockerhubUsername}/${IMAGE_NAME}:${IMAGE_TAG} .
                                docker tag ${dockerhubUsername}/${IMAGE_NAME}:${IMAGE_TAG} ${dockerhubUsername}/${IMAGE_NAME}:latest
                            """
                        } else {
                            bat """
                                docker build -t ${dockerhubUsername}/${IMAGE_NAME}:${IMAGE_TAG} .
                                docker tag ${dockerhubUsername}/${IMAGE_NAME}:${IMAGE_TAG} ${dockerhubUsername}/${IMAGE_NAME}:latest
                            """
                        }
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            when {
                expression {
                    return env.DOCKERHUB_USERNAME != null && env.DOCKERHUB_USERNAME != 'local'
                }
            }
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                                     usernameVariable: 'DOCKER_USER',
                                                     passwordVariable: 'DOCKER_PASS')]) {
                        if (isUnix()) {
                            sh """
                                echo \${DOCKER_PASS} | docker login -u \${DOCKER_USER} --password-stdin
                                docker push \${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                                docker push \${DOCKER_USER}/${IMAGE_NAME}:latest
                            """
                        } else {
                            bat """
                                echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin
                                docker push %DOCKER_USER%/${IMAGE_NAME}:${IMAGE_TAG}
                                docker push %DOCKER_USER%/${IMAGE_NAME}:latest
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes cluster...'
                script {
                    dir("${WORKSPACE_PATH}") {
                        def dockerhubUsername = env.DOCKERHUB_USERNAME ?: 'local'

                        // Use the kubeconfig credential
                        withCredentials([file(credentialsId: 'localkubeconfig', variable: 'KUBECONFIG')]) {
                            if (isUnix()) {
                                sh """
                                    export KUBECONFIG=\${KUBECONFIG}

                                    # Test kubectl connection
                                    kubectl cluster-info

                                    # Update deployment image or create if not exists
                                    kubectl set image deployment/abstergo-website-deployment abstergo-website=${dockerhubUsername}/${IMAGE_NAME}:${IMAGE_TAG} || echo "Deployment not found, will create..."

                                    # Apply manifests
                                    kubectl apply -f k8s/deployment.yaml
                                    kubectl apply -f k8s/service.yaml
                                    kubectl apply -f k8s/hpa.yaml

                                    # Wait for rollout
                                    kubectl rollout status deployment/abstergo-website-deployment --timeout=2m
                                """
                            } else {
                                bat """
                                    set KUBECONFIG=%KUBECONFIG%

                                    kubectl cluster-info
                                    kubectl set image deployment/abstergo-website-deployment abstergo-website=${dockerhubUsername}/${IMAGE_NAME}:${IMAGE_TAG} || echo Deployment not found, will create...
                                    kubectl apply -f k8s/deployment.yaml
                                    kubectl apply -f k8s/service.yaml
                                    kubectl apply -f k8s/hpa.yaml
                                    kubectl rollout status deployment/abstergo-website-deployment --timeout=2m
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Verifying deployment...'
                script {
                    withCredentials([file(credentialsId: 'localkubeconfig', variable: 'KUBECONFIG')]) {
                        if (isUnix()) {
                            sh """
                                export KUBECONFIG=\${KUBECONFIG}
                                kubectl get pods -l app=abstergo-website
                                kubectl get svc abstergo-website-service
                                echo ""
                                echo "Application deployed successfully!"
                                echo "Access via: kubectl port-forward svc/abstergo-website-service 8081:80"
                            """
                        } else {
                            bat """
                                set KUBECONFIG=%KUBECONFIG%
                                kubectl get pods -l app=abstergo-website
                                kubectl get svc abstergo-website-service
                                echo.
                                echo Application deployed successfully!
                                echo Access via: kubectl port-forward svc/abstergo-website-service 8081:80
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo 'Cleaning up...'
                try {
                    if (isUnix()) {
                        sh 'docker logout || true'
                    } else {
                        bat 'docker logout || exit 0'
                    }
                } catch (Exception e) {
                    echo "Docker logout failed: ${e.message}"
                }
            }
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed! Check the logs above for details.'
        }
    }
}
