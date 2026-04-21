# 8byte Banking App

Boardgame database application deployed on AWS EKS as part of the 8byte banking platform CI/CD pipeline.

---

## Application overview

A Spring Boot web application for browsing and managing board games with role-based access control. Deployed using a fully automated Jenkins CI/CD pipeline with security scanning, code quality gates, and multi-environment deployment.

**Tech stack:** Java 17, Spring Boot 2.7.18, Spring Security, Thymeleaf, H2 Database, Maven

---

## Repository structure

```
8byte-banking-app/
├── src/                    # Java source code
├── k8s/                    # Kubernetes manifests
│   ├── namespace.yaml      # staging and production namespaces
│   ├── deployment.yaml     # application deployment
│   └── service.yaml        # LoadBalancer service
├── docs/                   # CI/CD documentation
│   ├── APPROACH-PHASE2.md
│   ├── CHALLENGES-PHASE2.md
│   └── RECOMMENDATIONS.md
├── Dockerfile              # Container image definition
├── Jenkinsfile             # CI/CD pipeline definition
└── pom.xml                 # Maven build configuration
```

---

## CI/CD pipeline

The pipeline is defined in `Jenkinsfile` and runs automatically via GitHub webhook on every push.

### Pipeline stages

```
PR builds (feature branches):
checkout → compile → test → trivy fs scan → sonarqube → quality gate

Main branch builds (full deployment):
checkout → compile → test → trivy fs scan → sonarqube → quality gate →
build → docker build → trivy image scan → push to ECR →
deploy to staging → manual approval → deploy to production
```

### Environment strategy

| Environment | Namespace | Trigger | Access |
|---|---|---|---|
| Staging | `staging` | Auto on merge to main | Internal ELB |
| Production | `production` | Manual approval | Internal ELB |

### Security gates

Every build passes through:
- **Trivy filesystem scan** — checks dependencies for known CVEs
- **SonarQube analysis** — static code analysis for bugs and vulnerabilities
- **Quality gate** — blocks deployment if quality thresholds not met
- **Trivy image scan** — checks Docker image layers for vulnerabilities

---

## Docker image

The application is packaged as a Docker image and stored in AWS ECR.

```dockerfile
FROM eclipse-temurin:21-jre-alpine
LABEL maintainer="Rahulbs06" project="8byte-banking-platform"
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY target/*.jar app.jar
RUN chown appuser:appgroup app.jar
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Key decisions:
- Runs as non-root user `appuser` — security best practice
- Alpine base image — minimal attack surface
- JAR copied from Jenkins workspace — no double compilation

---

## Kubernetes deployment

Application deploys to EKS with 2 replicas per environment.

```yaml
replicas: 2
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

Service type is `LoadBalancer` — AWS automatically creates a Classic Load Balancer for external access.

---

## Running locally

```bash
# Clone the repository
git clone https://github.com/Rahulbs06/8byte-banking-app.git
cd 8byte-banking-app

# Build
mvn clean package

# Run
java -jar target/*.jar

# Access
open http://localhost:8080
```

---

## Jenkins setup

Jenkins is hosted on an EC2 instance provisioned by Terraform. See the infrastructure repository for setup details.

Required Jenkins credentials:
```
git-cred      → GitHub personal access token
sonar-token   → SonarQube analysis token
aws-access-key → AWS access key ID
aws-secret-key → AWS secret access key
```

Required Jenkins tools:
```
jdk21         → Java 21 installation
maven3        → Maven 3.9.9
sonar-scanner → SonarQube Scanner 8.0.1
```

---

## Infrastructure repository

All AWS infrastructure is managed separately:

[https://github.com/Rahulbs06/8byte-devops](https://github.com/Rahulbs06/8byte-devops)

---

## Production recommendations

See `docs/RECOMMENDATIONS.md` for production improvements including:
- HPA for autoscaling
- Ingress over LoadBalancer
- Network policies
- RBAC for Jenkins service account
- Liveness and readiness probes
- Distroless base images