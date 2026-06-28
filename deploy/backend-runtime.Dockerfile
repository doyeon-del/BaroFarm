# 사전 빌드된 jar(네이티브 빌드)을 amd64 JRE에 얹어 조립 — emulated Maven 빌드 회피.
# 사용: docker buildx build --platform linux/amd64 -f deploy/backend-runtime.Dockerfile -t barofarm-prod-backend:latest backend/
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
