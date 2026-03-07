FROM eclipse-temurin:25.0.2_10-jre-ubi10-minimal

RUN mkdir app

WORKDIR /app

COPY target/java-maven-app-*.jar .

EXPOSE 8080

CMD java -jar java-maven-app-*.jar