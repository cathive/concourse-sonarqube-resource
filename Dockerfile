# ======================
# Global build arguments
# ======================
ARG MAVEN_VERSION="3.6.1"
ARG MAVEN_SHA512_CHECKSUM="51169366d7269ed316bad013d9cbfebe3a4ef1fda393ac4982d6dbc9af2d5cc359ee12838b8041cb998f236486e988b9c05372f4fdb29a96c1139f63c991e90e"
ARG SONAR_SCANNER_CLI_VERSION="4.0.0.1744"
ARG SONAR_SCANNER_CLI_SHA512_CHECKSUM="d65f83ea8f33c6f1b687cfe9db95567012dae97d2935ca2014814b364d2f87f81a1e5ab13dcd5ea5b7fda57f3b2d620a2bd862fb2d87c918c8e2f6f6ff2eca29"
ARG SONAR_SCANNER_MAVEN_PLUGIN_VERSION="3.6.0.1398"

# =================================================
# Builder image (just for downloads / preparations)
# =================================================
FROM debian:jessie as builder
RUN apt-get -y update && apt-get -y install curl unzip
ARG MAVEN_VERSION
ARG MAVEN_SHA512_CHECKSUM
ARG SONAR_SCANNER_CLI_VERSION
ARG SONAR_SCANNER_CLI_SHA512_CHECKSUM
ARG SONAR_SCANNER_DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux.zip"
RUN curl -s -L "${SONAR_SCANNER_DOWNLOAD_URL}" > "/tmp/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux.zip"
RUN echo "${SONAR_SCANNER_CLI_SHA512_CHECKSUM}  /tmp/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux.zip" | sha512sum -c
RUN unzip -qq "/tmp/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux.zip" -d "/data"
RUN mv "/data/sonar-scanner-${SONAR_SCANNER_CLI_VERSION}-linux" "/data/sonar-scanner"
RUN rm -f "/tmp/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux.zip"

ARG MAVEN_DOWNLOAD_URL="http://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.zip"
RUN curl -s -L "${MAVEN_DOWNLOAD_URL}" > "/tmp/apache-maven-${MAVEN_VERSION}-bin.zip"
RUN echo "${MAVEN_SHA512_CHECKSUM}  /tmp/apache-maven-${MAVEN_VERSION}-bin.zip" | sha512sum -c
RUN unzip -qq "/tmp/apache-maven-${MAVEN_VERSION}-bin.zip" -d "/data"
RUN mv "/data/apache-maven-${MAVEN_VERSION}" "/data/apache-maven"
RUN rm -f "/tmp/apache-maven-${MAVEN_VERSION}-bin.zip"

# ===========
# Final image
# ===========
FROM openjdk:8u151-alpine
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

ARG SONAR_SCANNER_MAVEN_PLUGIN_VERSION
RUN mvn -q org.apache.maven.plugins:maven-dependency-plugin:3.1.1:get \
-DrepoUrl="https://repo.maven.apache.org/maven2/" \
-Dartifact="org.sonarsource.scanner.maven:sonar-maven-plugin:${SONAR_SCANNER_MAVEN_PLUGIN_VERSION}:jar"

ENV PATH="/usr/local/bin:/usr/bin:/bin"

LABEL maintainer="Benjamin P. Jung <headcr4sh@gmail.com>" \
      version="0.10.0" \
      maven.version="{MAVEN_VERSION}" \
      sonar-scanner.cli.version="${SONAR_SCANNER_CLI_VERSION}" \
      sonar-scanner.maven-plugin.version="${SONAR_SCANNER_MAVEN_PLUGIN_VERSION}" \
      org.concourse-ci.target-version="5.7.0" \
      org.concourse-ci.resource-id="sonarqube" \
      org.concourse-ci.resource-name="SonarQube Static Code Analysis" \
      org.concourse-ci.resource-homepage="https://github.com/cathive/concourse-sonarqube-resource"

COPY ./assets/* /opt/resource/


