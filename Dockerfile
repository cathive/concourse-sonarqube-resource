# ======================
# Global build arguments
# ======================
ARG RESOURCE_VERSION="0.14.3"
ARG MAVEN_VERSION="3.9.5"
ARG MAVEN_SHA512_CHECKSUM="ca59380b839c6bea8f464a08bb7873a1cab91007b95876ba9ed8a9a2b03ceac893e661d218ba3d4af3ccf46d26600fc4c59fccabba9d7b2cc4adcd8aecc1df2a"
ARG SONAR_SCANNER_CLI_VERSION="4.7.0.2747"
ARG SONAR_SCANNER_CLI_SHA512_CHECKSUM="92475d0b32d15c3602657852e8670b862ba2d1a1ecafefbc40c2b176173375e21931ae94c5966f454d31e3dea7fb3033cec742498660cf0dc0ff9fa742a9fe4a"
ARG SONAR_SCANNER_MAVEN_PLUGIN_VERSION="3.9.1.2184"

# =================================================
# Builder image (just for downloads / preparations)
# =================================================
FROM docker.io/library/debian:stable-slim as builder
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

ARG MAVEN_DOWNLOAD_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.zip"
RUN curl -s -L "${MAVEN_DOWNLOAD_URL}" > "/tmp/apache-maven-${MAVEN_VERSION}-bin.zip"
RUN echo "${MAVEN_SHA512_CHECKSUM}  /tmp/apache-maven-${MAVEN_VERSION}-bin.zip" | sha512sum -c
RUN unzip -qq "/tmp/apache-maven-${MAVEN_VERSION}-bin.zip" -d "/data"
RUN mv "/data/apache-maven-${MAVEN_VERSION}" "/data/apache-maven"
RUN rm -f "/tmp/apache-maven-${MAVEN_VERSION}-bin.zip"

# ===========
# Final image
# ===========
FROM docker.io/openjdk:17-slim

ARG NODE_MAJOR=20
ARG TYPESCRIPT_VERSION="5.0.4"

# Install nodejs
RUN apt-get -y update && apt-get -y install bash curl gawk git jq shellcheck ca-certificates gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install nodejs -y && \
    npm install -g typescript@${TYPESCRIPT_VERSION}

RUN ln -sf "${JAVA_HOME}/bin/java" "/usr/local/bin/java" && \
    ln -sf "${JAVA_HOME}/bin/javac" "/usr/local/bin/javac" && \
    ln -sf "${JAVA_HOME}/bin/jar" "/usr/local/bin/jar"

# TODO How should we do this with Slim?
# https://github.com/concourse/concourse/issues/2042
#RUN unlink  $JAVA_HOME/lib/security/cacerts && \
#cp "/etc/ssl/certs/java/cacerts" "${JAVA_HOME}/lib/security/cacerts"

COPY --from=builder "/data/sonar-scanner" "/opt/sonar-scanner"
RUN rm -Rf "/opt/sonar-scanner/jre" \
&& ln -sf "${JAVA_HOME}" "/opt/sonar-scanner/jre" \
&& ln -sf "/opt/sonar-scanner/bin/sonar-scanner" "/usr/local/bin/sonar-scanner" \
&& ln -sf "/opt/sonar-scanner/bin/sonar-scanner-debug" "/usr/local/bin/sonar-scanner-debug"
COPY --from=builder "/data/apache-maven" "/opt/apache-maven"
RUN ln -sf "/opt/apache-maven/bin/mvn" "/usr/local/bin/mvn" \
&& ln -sf "/opt/apache-maven/bin/mvnDebug" "/usr/local/bin/mvnDebug"
ENV M2_HOME="/opt/apache-maven"

ARG SONAR_SCANNER_MAVEN_PLUGIN_VERSION
RUN mvn -q org.apache.maven.plugins:maven-dependency-plugin:3.3.0:get \
-DrepoUrl="https://repo.maven.apache.org/maven2/" \
-Dartifact="org.sonarsource.scanner.maven:sonar-maven-plugin:${SONAR_SCANNER_MAVEN_PLUGIN_VERSION}:jar"

ENV NODE_PATH="/usr/local/lib/node_modules"
ENV PATH="/usr/local/bin:/usr/bin:/bin"

LABEL maintainer="Benjamin P. Jung <headcr4sh@gmail.com>" \
      version="${RESOURCE_VERSION}" \
      maven.version="{MAVEN_VERSION}" \
      sonar-scanner.cli.version="${SONAR_SCANNER_CLI_VERSION}" \
      sonar-scanner.maven-plugin.version="${SONAR_SCANNER_MAVEN_PLUGIN_VERSION}" \
      typescript.version=${TYPESCRIPT_VERSION} \
      org.concourse-ci.target-version="6.6.0" \
      org.concourse-ci.resource-id="sonarqube" \
      org.concourse-ci.resource-name="SonarQube Static Code Analysis" \
      org.concourse-ci.resource-homepage="https://github.com/cathive/concourse-sonarqube-resource"

# org.opencontainers annotations / labels.
# See https://github.com/opencontainers/image-spec/blob/main/annotations.md for further details.
LABEL org.opencontainers.image.title="concourse-sonarqube-resource"
LABEL org.opencontainers.image.description="Concourse CI resource to interact with SonarQube"
LABEL org.opencontainers.image.source="https://github.com/cathive/concourse-sonarqube-resource"
LABEL org.opencontainers.image.vendor="The Cat Hive Developers"
LABEL org.opencontainers.image.licenses="LicenseRef-apache-2.0"
LABEL org.opencontainers.image.version="${RESOURCE_VERSION}"

COPY ./assets/* /opt/resource/
