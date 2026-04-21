FROM eclipse-temurin:21-jre-alpine
LABEL maintainer="Rahulbs06" \
      project="8byte-banking-platform"
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY target/*.jar app.jar
RUN chown appuser:appgroup app.jar
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]