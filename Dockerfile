FROM eclipse-temurin:21-jre

WORKDIR /app

COPY target/akka-sbr-demo-1.0-SNAPSHOT.jar /app/app.jar

# Install curl for health/management checks if needed
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

CMD ["java", "-jar", "app.jar"]
