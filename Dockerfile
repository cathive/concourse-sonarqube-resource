FROM debian:jessie as builder
RUN apt-get -y update && apt-get -y install curl unzip
ARG SONAR_SCANNER_DOWNLOAD_URL="https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.2.0.1227-linux.zip"
RUN curl -s -L "${SONAR_SCANNER_DOWNLOAD_URL}" > "/tmp/sonar-scanner-cli-3.2.0.1227-linux.zip" \
&& unzip -qq "/tmp/sonar-scanner-cli-3.2.0.1227-linux.zip" -d "/data" \
&& mv "/data/sonar-scanner-3.2.0.1227-linux" "/data/sonar-scanner" \
&& rm -f "/tmp/sonar-scanner-cli-3.2.0.1227-linux.zip"
ARG MAVEN_DOWNLOAD_URL="http://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.zip"
RUN curl -s -L "${MAVEN_DOWNLOAD_URL}" > "/tmp/apache-maven-3.5.3-bin.zip" \
&& unzip -qq "/tmp/apache-maven-3.5.3-bin.zip" -d "/data" \
&& mv "/data/apache-maven-3.5.3" "/data/apache-maven" \
&& rm -f "/tmp/apache-maven-3.5.3-bin.zip"

FROM openjdk:8-jdk-alpine3.7
RUN apk -f -q update \
&& apk -f -q add bash curl gawk git jq nodejs

# https://github.com/concourse/concourse/issues/2042
RUN unlink  $JAVA_HOME/jre/lib/security/cacerts && \
cp "/etc/ssl/certs/java/cacerts" "${JAVA_HOME}/jre/lib/security/cacerts"

COPY --from=builder "/data/sonar-scanner" "/opt/sonar-scanner"
RUN rm -Rf "/opt/sonar-scanner/jre" \
&& ln -sf "/usr" "/opt/sonar-scanner/jre" \
&& ln -sf "/opt/sonar-scanner/bin/sonar-scanner" "/usr/local/bin/sonar-scanner" \
&& ln -sf "/opt/sonar-scanner/bin/sonar-scanner-debug" "/usr/local/bin/sonar-scanner-debug"
COPY --from=builder "/data/apache-maven" "/opt/apache-maven"
RUN ln -sf "/opt/apache-maven/bin/mvn" "/usr/local/bin/mvn" \
&& ln -sf "/opt/apache-maven/bin/mvnDebug" "/usr/local/bin/mvnDebug"
ENV M2_HOME="/opt/apache-maven"

RUN mvn -q org.apache.maven.plugins:maven-dependency-plugin:3.1.1:get \
-DrepoUrl="https://repo.maven.apache.org/maven2/" \
-Dartifact="org.sonarsource.scanner.maven:sonar-maven-plugin:3.4.0.905:jar"

ENV PATH="/usr/local/bin:/usr/bin:/bin"

LABEL maintainer="Benjamin P. Jung <headcr4sh@gmail.com>" \
      version="0.6.0.3" \
      org.concourse-ci.target-version="3.13.0" \
      org.concourse-ci.resource-id="sonarqube" \
      org.concourse-ci.resource-name="SonarQube Static Code Analysis" \
      org.concourse-ci.resource-homepage="https://github.com/marek-urban/concourse-sonarqube-resource"

COPY ./assets/* /opt/resource/
