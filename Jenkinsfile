pipeline {
    agent any

    tools {
        jdk 'jdk21'
        maven 'maven3'
    }

    environment {
        SCANNER_HOME     = tool 'sonar-scanner'
        AWS_REGION       = 'ap-south-1'
        ECR_REGISTRY     = '188019708471.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPO         = '8byte-prod-app'
        IMAGE_TAG        = "${BUILD_NUMBER}"
        EKS_CLUSTER      = '8byte-prod-eks-cluster'
        SONAR_URL        = 'http://65.2.172.36:9000'
    }

    stages {

        stage('checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'git-cred',
                    url: 'https://github.com/Rahulbs06/8byte-banking-app.git'
            }
        }

        stage('compile') {
            steps {
                sh 'mvn compile'
            }
        }

        stage('test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('trivy fs scan') {
            steps {
                sh 'trivy fs --format table -o trivy-fs-report.html .'
            }
        }

        stage('sonarqube analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=8byte-banking-app \
                        -Dsonar.projectKey=8byte-banking-app \
                        -Dsonar.java.binaries=.
                    '''
                }
            }
        }

        stage('quality gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false,
                        credentialsId: 'sonar-token'
                }
            }
        }

        stage('build') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }

        stage('docker build') {
            steps {
                sh "docker build -t ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} ."
            }
        }

        stage('trivy image scan') {
            steps {
                sh "trivy image --format table -o trivy-image-report.html ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('push to ecr') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                    docker tag ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:latest
                    docker push ${ECR_REGISTRY}/${ECR_REPO}:latest
                """
            }
        }

        stage('deploy to staging') {
            steps {
                sh """
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER}
                    kubectl apply -f k8s/namespace.yaml
                    kubectl apply -f k8s/ -n staging
                    kubectl set image deployment/8byte-app 8byte-app=${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} -n staging
                    kubectl rollout status deployment/8byte-app -n staging
                """
            }
        }

        stage('approval') {
            steps {
                input message: 'Deploy to production?', ok: 'Yes'
            }
        }

        stage('deploy to production') {
            steps {
                sh """
                    kubectl apply -f k8s/ -n production
                    kubectl set image deployment/8byte-app 8byte-app=${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} -n production
                    kubectl rollout status deployment/8byte-app -n production
                """
            }
        }
    }

    post {
        failure {
            mail to: 'rahul@8byte.ai',
                 subject: "Pipeline failed: ${JOB_NAME} #${BUILD_NUMBER}",
                 body: "Check Jenkins: ${BUILD_URL}"
        }
    }
}