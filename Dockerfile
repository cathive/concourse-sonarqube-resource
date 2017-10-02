FROM debian:jessie as builder
RUN apt-get -y update && apt-get -y install curl unzip
ARG SONAR_RUNNER_DOWNLOAD_URL="http://repo1.maven.org/maven2/org/codehaus/sonar/runner/sonar-runner-dist/2.4/sonar-runner-dist-2.4.zip"
RUN curl -s -L "${SONAR_RUNNER_DOWNLOAD_URL}" > "/tmp/sonar-runner-dist-2.4.zip" \
&& unzip "/tmp/sonar-runner-dist-2.4.zip" -d "/data" \
&& rm -f "/tmp/sonar-runner-dist-2.4.zip"
#ARG JQ_DOWNLOAD_URL="https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"
#RUN curl -s -L "${JQ_DOWNLOAD_URL}" >/data/jq

FROM openjdk:8u131-alpine
MAINTAINER Benjamin P. Jung <headcr4sh@gmail.com>
RUN apk -f -q update \
&& apk -f -q add bash gawk git jq
COPY --from=builder "/data/sonar-runner-2.4" /opt/sonar-runner
RUN ln -sf /opt/sonar-runner/bin/sonar-runner /usr/local/bin/sonar-runner
#COPY --from=builder "/data/jq" /usr/local/bin/jq

COPY ./assets/* /opt/resources/

ENV PATH="/usr/local/bin:/usr/bin:/bin"
