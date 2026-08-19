#!/usr/bin/env bash
set -Eeuo pipefail

grep -Fq '<module>bigquery</module>' server/drivers/pom.xml
grep -Fq '<artifactId>drivers.bigquery</artifactId>' server/drivers/bigquery/pom.xml
grep -Fq '<artifactId>google-cloud-bigquery-jdbc</artifactId>' server/drivers/bigquery/pom.xml
grep -Fq '<version>1.2.0</version>' server/drivers/bigquery/pom.xml
grep -Fq '<resource name="drivers/google-bigquery"/>' server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
grep -Fq '<bundle id="drivers.google-bigquery" label="Google BigQuery drivers"/>' server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
grep -Fq '<driver id="bigquery:google_bigquery_jdbc"/>' server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
grep -Fq 'FROM node:24.13.1-bookworm AS builder' deploy/docker/cloudbeaver-ce/Dockerfile
grep -Fq 'COPY . /workspace/cloudbeaver' deploy/docker/cloudbeaver-ce/Dockerfile
grep -Fq 'RUN ./build.sh' deploy/docker/cloudbeaver-ce/Dockerfile
grep -Fq 'COPY --from=builder /workspace/cloudbeaver/deploy/cloudbeaver /opt/cloudbeaver' deploy/docker/cloudbeaver-ce/Dockerfile
awk '
    /^FROM / { fromCount++ }
    fromCount == 0 && /^ARG BASE_JAVA_TAG=/ { declared = 1 }
    /^FROM dbeaver\/base-java:\$\{BASE_JAVA_TAG\}/ { exit !declared }
' deploy/docker/cloudbeaver-ce/Dockerfile
grep -Fq 'deploy/docker/cloudbeaver-ce/Dockerfile' deploy/docker/cloudbeaver-ce/README.md
grep -Fq '/opt/cloudbeaver/workspace' deploy/docker/cloudbeaver-ce/README.md
grep -Fq 'OAuthType' deploy/docker/cloudbeaver-ce/README.md
grep -Fq 'OAuthPvtKey' deploy/docker/cloudbeaver-ce/README.md
grep -Fq 'Never commit the JSON key' deploy/docker/cloudbeaver-ce/README.md
