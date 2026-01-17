pipeline {
    agent any

    stages {
        stage('Clone Code') {
            steps {
                git url: 'https://github.com/yourusername/myapp.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t myapp:$BUILD_NUMBER .'
            }
        }

        stage('Deploy Green') {
            steps {
                sh 'kubectl apply -f k8s/green/deployment-green.yaml -n green'
            }
        }

        stage('Manual Approval') {
            steps {
                input message: 'Approve deployment to production?'
            }
        }

        stage('Switch Traffic') {
            steps {
                sh '''
                kubectl patch service myapp-service -n production \
                -p '{"spec":{"selector":{"app":"myapp-green"}}}'
                '''
            }
        }
    }
}
