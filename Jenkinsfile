pipeline {
    agent any

    environment {
        // Change this to your registry (e.g. index.docker.io/<username>)
        REGISTRY_URL   = 'myregistry.example.com'
        IMAGE_NAME     = 'my-app'
        REGISTRY_CRED  = 'docker-registry-credentials-id' // Jenkins credential ID

        // Kubernetes
        KUBE_CONTEXT   = 'default'        // change if you use multiple kube contexts
        KUBE_NAMESPACE = 'prod'           // single namespace for blue/green
        SERVICE_NAME   = 'my-app-service' // Kubernetes Service name in prod
    }

    stages {
        stage('Checkout & Build Image') {
            steps {
                checkout scm
                script {
                    def imageTag = "${env.BUILD_NUMBER}"
                    sh """
                      docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${imageTag} .
                    """
                }
            }
        }

        stage('Push Image') {
            steps {
                script {
                    def imageTag = "${env.BUILD_NUMBER}"
                    withCredentials([
                        usernamePassword(credentialsId: REGISTRY_CRED,
                                         usernameVariable: 'REG_USER',
                                         passwordVariable: 'REG_PASS')
                    ]) {
                        sh """
                          echo "$REG_PASS" | docker login ${REGISTRY_URL} -u "$REG_USER" --password-stdin
                          docker push ${REGISTRY_URL}/${IMAGE_NAME}:${imageTag}
                          docker logout ${REGISTRY_URL}
                        """
                    }
                }
            }
        }

        stage('Deploy to Green') {
            steps {
                script {
                    def imageTag = "${env.BUILD_NUMBER}"
                    sh """
                      # Optional: set kube context if you use named contexts
                      kubectl config use-context ${KUBE_CONTEXT} || true

                      # Update the GREEN deployment to use new image
                      kubectl -n ${KUBE_NAMESPACE} set image deployment/${IMAGE_NAME}-green ${IMAGE_NAME}=${REGISTRY_URL}/${IMAGE_NAME}:${imageTag} --record

                      # Wait until GREEN deployment is ready
                      kubectl -n ${KUBE_NAMESPACE} rollout status deployment/${IMAGE_NAME}-green --timeout=120s
                    """
                }
            }
        }

        stage('Manager Approval to Switch Traffic') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Approve switching PRODUCTION traffic to the new GREEN version?',
                          ok: 'Approve'
                }
            }
        }

        stage('Switch Production Traffic to Green') {
            steps {
                script {
                    sh """
                      kubectl config use-context ${KUBE_CONTEXT} || true

                      # Point the Service selector to version=green pods
                      kubectl -n ${KUBE_NAMESPACE} set selector svc/${SERVICE_NAME} app=${IMAGE_NAME},version=green

                      # Show the updated Service for verification
                      kubectl -n ${KUBE_NAMESPACE} describe svc ${SERVICE_NAME} | sed -n '1,40p'
                    """
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed. Production traffic remains on the previous version (likely BLUE).'
        }
        success {
            echo 'Production traffic has been switched to GREEN successfully.'
        }
    }
}
