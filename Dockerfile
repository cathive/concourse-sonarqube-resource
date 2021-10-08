# ======================
# Global build arguments
# ======================
ARG MAVEN_VERSION="3.8.3"
ARG MAVEN_SHA512_CHECKSUM="959de0db3e342ecf1c183b321799a836c3c10738126f3302b623376efa45c6769ccb5cd32a17f9a9a8eb64bb30f13a6a0e4170bf03a7707cfba6d41392107e93"
ARG SONAR_SCANNER_CLI_VERSION="4.6.2.2472"
ARG SONAR_SCANNER_CLI_SHA512_CHECKSUM="87828af6552a74a3395c475c409a29fa0d13ae8d90e27273f59c6163b273330a782b5944be76c2e44931a8994dedb7b2ea83aa44f3c5ff009e680584331d36bd"
ARG SONAR_SCANNER_MAVEN_PLUGIN_VERSION="3.7.0.1746"

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
FROM openjdk:11.0.8-slim
RUN apt-get -y update \
&& apt-get -y install bash curl gawk git jq nodejs npm

ARG TYPESCRIPT_VERSION="3.9.7"
RUN npm install -g typescript@${TYPESCRIPT_VERSION}

RUN ln -sf "${JAVA_HOME}/bin/java" "/usr/local/bin/java" \
&& ln -sf "${JAVA_HOME}/bin/javac" "/usr/local/bin/javac" \
&& ln -sf "${JAVA_HOME}/bin/jar" "/usr/local/bin/jar"

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
RUN mvn -q org.apache.maven.plugins:maven-dependency-plugin:3.1.2:get \
-DrepoUrl="https://repo.maven.apache.org/maven2/" \
-Dartifact="org.sonarsource.scanner.maven:sonar-maven-plugin:${SONAR_SCANNER_MAVEN_PLUGIN_VERSION}:jar"

ENV NODE_PATH="/usr/local/lib/node_modules"
ENV PATH="/usr/local/bin:/usr/bin:/bin"

LABEL maintainer="Benjamin P. Jung <headcr4sh@gmail.com>" \
      version="0.13.2" \
      maven.version="{MAVEN_VERSION}" \
      sonar-scanner.cli.version="${SONAR_SCANNER_CLI_VERSION}" \
      sonar-scanner.maven-plugin.version="${SONAR_SCANNER_MAVEN_PLUGIN_VERSION}" \
      typescript.version=${TYPESCRIPT_VERSION} \
      org.concourse-ci.target-version="6.6.0" \
      org.concourse-ci.resource-id="sonarqube" \
      org.concourse-ci.resource-name="SonarQube Static Code Analysis" \
      org.concourse-ci.resource-homepage="https://github.com/cathive/concourse-sonarqube-resource"

COPY ./assets/* /opt/resource/


