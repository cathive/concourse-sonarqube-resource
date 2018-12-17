FROM debian:jessie as builder
RUN apt-get -y update && apt-get -y install curl unzip

ARG SONAR_SCANNER_DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.2.0.1227-linux.zip"
RUN curl -s -L "${SONAR_SCANNER_DOWNLOAD_URL}" > "/tmp/sonar-scanner-cli-3.2.0.1227-linux.zip"
RUN echo "17b5a39b2790c42d6894c8b56b866a4c7591f0fcf83d54aa46b7a3dd61e05c5030c99ea074b9d4338abe30387a71de302e4fda4b843e6e404f0c53c62f142a3b  /tmp/sonar-scanner-cli-3.2.0.1227-linux.zip" | sha512sum -c
RUN unzip -qq "/tmp/sonar-scanner-cli-3.2.0.1227-linux.zip" -d "/data"
RUN mv "/data/sonar-scanner-3.2.0.1227-linux" "/data/sonar-scanner"
RUN rm -f "/tmp/sonar-scanner-cli-3.2.0.1227-linux.zip"

ARG MAVEN_DOWNLOAD_URL="http://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/maven/maven-3/3.6.0/binaries/apache-maven-3.6.0-bin.zip"
RUN curl -s -L "${MAVEN_DOWNLOAD_URL}" > "/tmp/apache-maven-3.6.0-bin.zip"
RUN echo "7d14ab2b713880538974aa361b987231473fbbed20e83586d542c691ace1139026f232bd46fdcce5e8887f528ab1c3fbfc1b2adec90518b6941235952d3868e9  /tmp/apache-maven-3.6.0-bin.zip" | sha512sum -c
RUN unzip -qq "/tmp/apache-maven-3.6.0-bin.zip" -d "/data"
RUN mv "/data/apache-maven-3.6.0" "/data/apache-maven"
RUN rm -f "/tmp/apache-maven-3.6.0-bin.zip"

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

ENV PATH="/usr/local/bin:/usr/bin:/bin"

LABEL maintainer="Benjamin P. Jung <headcr4sh@gmail.com>" \
      version="0.7.2" \
      org.concourse-ci.target-version="4.2.1" \
      org.concourse-ci.resource-id="sonarqube" \
      org.concourse-ci.resource-name="SonarQube Static Code Analysis" \
      org.concourse-ci.resource-homepage="https://github.com/cathive/concourse-sonarqube-resource"

COPY ./assets/* /opt/resource/


