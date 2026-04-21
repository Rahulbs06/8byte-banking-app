# 8byte Banking App

Boardgame application deployed as part of 8byte banking platform CI/CD pipeline.

## Tech Stack
- Java 21
- Spring Boot
- Maven
- Docker
- Kubernetes (EKS)

## Pipeline
Jenkins CI/CD pipeline handles:
- Code compilation and testing
- SonarQube code quality analysis
- Trivy security scanning
- Docker image build and push to ECR
- Deployment to staging namespace
- Manual approval gate
- Deployment to production namespace

## Repository Structure
- `src/` - Java source code
- `k8s/` - Kubernetes manifests
- `Dockerfile` - Container image definition
- `Jenkinsfile` - CI/CD pipeline definition