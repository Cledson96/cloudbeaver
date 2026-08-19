ARG BASE_JAVA_TAG="stable"
ARG MAVEN_VERSION=3.9.11

FROM node:24.13.1-bookworm AS builder

ARG MAVEN_VERSION

COPY --from=eclipse-temurin:21-jdk-noble /opt/java/openjdk /opt/java/openjdk

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:/opt/apache-maven/bin:${PATH}"

RUN apt-get update && \
    apt-get install --yes --no-install-recommends ca-certificates curl git && \
    curl --fail --location --silent --show-error \
        "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
        | tar --extract --gzip --directory /opt && \
    ln --symbolic "/opt/apache-maven-${MAVEN_VERSION}" /opt/apache-maven && \
    corepack enable && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY . /workspace/cloudbeaver

RUN git clone --depth 1 https://github.com/dbeaver/dbeaver-common.git /workspace/dbeaver-common && \
    git clone --depth 1 https://github.com/dbeaver/dbeaver.git /workspace/dbeaver

WORKDIR /workspace/cloudbeaver/deploy

RUN ./build.sh

FROM dbeaver/base-java:${BASE_JAVA_TAG}

LABEL org.opencontainers.image.title="CloudBeaver Community with Google BigQuery JDBC driver"

ENV DBEAVER_GID=8978
ENV DBEAVER_UID=8978

RUN groupadd --gid "$DBEAVER_GID" dbeaver && \
    useradd --gid "$DBEAVER_GID" --create-home --uid "$DBEAVER_UID" --shell /bin/bash dbeaver

COPY --from=builder /workspace/cloudbeaver/deploy/cloudbeaver /opt/cloudbeaver
COPY --from=builder /workspace/cloudbeaver/deploy/scripts/launch-product.sh /opt/cloudbeaver/launch-product.sh

RUN find /opt/cloudbeaver -type d -exec chmod 775 {} \; && \
    chown --recursive dbeaver:dbeaver /opt/cloudbeaver && \
    chmod +x /opt/cloudbeaver/run-cloudbeaver-server.sh /opt/cloudbeaver/launch-product.sh

WORKDIR /opt/cloudbeaver

EXPOSE 8978

USER dbeaver

ENTRYPOINT ["./launch-product.sh"]
