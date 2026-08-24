# ========================================================================================
# Global build arguments
# ========================================================================================
ARG SONAR_SCANNER_CLI_VERSION="8.0.1.6346"

# ========================================================================================
# Builder image (just for downloads / preparations)
# ========================================================================================
FROM docker.io/library/debian:stable-slim AS builder

RUN apt-get -y update && apt-get -y install curl unzip

ARG MAVEN_VERSION="3.9.16"
ARG MAVEN_SHA512_CHECKSUM="ed41650d42485cfc243fad22158caf9cbb5dc408ce7a09ddb94dd42a019de929ca43065bfa450612cf12bf78b5cafa3884b96c090de326ff590448c933454af3"

ARG MAVEN_DOWNLOAD_URL="https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.zip"
RUN curl -s -L --fail "${MAVEN_DOWNLOAD_URL}" > "/tmp/apache-maven-${MAVEN_VERSION}-bin.zip" && \
    echo "${MAVEN_SHA512_CHECKSUM}  /tmp/apache-maven-${MAVEN_VERSION}-bin.zip" | sha512sum -c && \
    unzip -qq "/tmp/apache-maven-${MAVEN_VERSION}-bin.zip" -d "/data" && \
    mv "/data/apache-maven-${MAVEN_VERSION}" "/data/apache-maven" && \
    rm -f "/tmp/apache-maven-${MAVEN_VERSION}-bin.zip"

ARG SONAR_SCANNER_CLI_VERSION
ARG SONAR_SCANNER_CLI_SHA512_CHECKSUM="0f9ea6231c0373834cf2b9f0935ae34314f83026687ebee4f6f6fa0843512f0754e101b21ef2ca5b839b1b2f08e2a5c758c9575e4ae5247a934b56e37931bd29"
ARG SONAR_SCANNER_DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux-x64.zip"

RUN curl -s -L "${SONAR_SCANNER_DOWNLOAD_URL}" > "/tmp/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux-x64.zip" && \
    echo "${SONAR_SCANNER_CLI_SHA512_CHECKSUM}" "/tmp/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux-x64.zip" | sha512sum -c && \
    unzip -qq "/tmp/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux-x64.zip" -d "/data" && \
    mv "/data/sonar-scanner-${SONAR_SCANNER_CLI_VERSION}-linux-x64" "/data/sonar-scanner" && \
    rm -f "/tmp/sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-linux-x64.zip"

# ========================================================================================
# Final image

# ========================================================================================
FROM docker.io/eclipse-temurin:26.0.2_10-jre-noble

ARG NODE_MAJOR=20
ARG TYPESCRIPT_VERSION="5.0.4"

# Install nodejs
RUN apt-get -y update && apt-get -y install bash curl gawk git jq shellcheck ca-certificates gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install nodejs -y && \
    npm install -g typescript@${TYPESCRIPT_VERSION} && \
    ln -sf "${JAVA_HOME}/bin/java" "/usr/local/bin/java" && \
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

ARG RESOURCE_VERSION="0.15.0"
ARG SONAR_SCANNER_CLI_VERSION
ARG SONAR_SCANNER_MAVEN_PLUGIN_VERSION="3.9.1.2184"

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
