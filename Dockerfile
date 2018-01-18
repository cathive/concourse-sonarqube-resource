FROM koalaman/shellcheck-alpine:latest AS shellcheck
COPY ./assets /assets
WORKDIR /assets
RUN /bin/shellcheck --shell=bash check in out *.sh

FROM debian:jessie as builder
RUN apt-get -y update && apt-get -y install curl unzip
ARG SONAR_SCANNER_DOWNLOAD_URL="https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip"
RUN curl -s -L "${SONAR_SCANNER_DOWNLOAD_URL}" > "/tmp/sonar-scanner-cli-3.0.3.778-linux.zip" \
&& unzip -qq "/tmp/sonar-scanner-cli-3.0.3.778-linux.zip" -d "/data" \
&& mv "/data/sonar-scanner-3.0.3.778-linux" "/data/sonar-scanner" \
&& rm -f "/tmp/sonar-scanner-cli-3.0.3.778-linux.zip"
ARG MAVEN_DOWNLOAD_URL="http://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.zip"
RUN curl -s -L "${MAVEN_DOWNLOAD_URL}" > "/tmp/apache-maven-3.5.2-bin.zip" \
&& unzip -qq "/tmp/apache-maven-3.5.2-bin.zip" -d "/data" \
&& mv "/data/apache-maven-3.5.2" "/data/apache-maven" \
&& rm -f "/tmp/apache-maven-3.5.2-bin.zip"

FROM openjdk:8u151-alpine
RUN apk -f -q update \
&& apk -f -q add bash curl gawk git jq nodejs
COPY --from=builder "/data/sonar-scanner" "/opt/sonar-scanner"
RUN rm -Rf "/opt/sonar-scanner/jre" \
&& ln -sf "/usr" "/opt/sonar-scanner/jre" \
&& ln -sf "/opt/sonar-scanner/bin/sonar-scanner" "/usr/local/bin/sonar-scanner" \
&& ln -sf "/opt/sonar-scanner/bin/sonar-scanner-debug" "/usr/local/bin/sonar-scanner-debug"
COPY --from=builder "/data/apache-maven" "/opt/apache-maven"
RUN ln -sf "/opt/apache-maven/bin/mvn" "/usr/local/bin/mvn" \
&& ln -sf "/opt/apache-maven/bin/mvnDebug" "/usr/local/bin/mvnDebug"
ENV M2_HOME="/opt/apache-maven"

RUN mvn -q org.apache.maven.plugins:maven-dependency-plugin:3.0.2:get \
-DrepoUrl="https://repo.maven.apache.org/maven2/" \
-Dartifact="org.sonarsource.scanner.maven:sonar-maven-plugin:3.4.0.905:jar"

ENV PATH="/usr/local/bin:/usr/bin:/bin"

LABEL maintainer="headcr4sh@gmail.com" \
      version="0.0.30"

COPY ./assets/* /opt/resource/


