# BigQuery Service Account Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and ship a CloudBeaver Community Docker image that exposes the Google BigQuery JDBC driver while allowing administrators to enter service-account JSON only through the running UI.

**Architecture:** A Maven driver module downloads the official Google JDBC dependency into the CloudBeaver driver distribution. The existing DBeaver BigQuery extension is enabled through CloudBeaver's resource registry. A multi-stage Dockerfile builds the complete distribution from the repository root and copies only the generated runtime files into the Java base image.

**Tech Stack:** Java 21, Maven 3.9.11, OSGi/Tycho, Google BigQuery JDBC 1.2.0, Node.js 24.13.1, Yarn 4.14.1, Docker, Bash.

**Spec:** `docs/superpowers/specs/2026-08-19-bigquery-service-account-design.md`

## Global Constraints

- Use the official `com.google.cloud:google-cloud-bigquery-jdbc:1.2.0` artifact.
- Register only `bigquery:google_bigquery_jdbc`; do not enable the legacy Simba driver.
- Never add a service-account JSON, project ID, connection configuration, or secret environment value to the repository or Docker image.
- The image must retain `/opt/cloudbeaver/workspace` as writable state owned by UID/GID 8978.
- The production driver path is `drivers/google-bigquery` and bundle ID is `drivers.google-bigquery`.
- Keep all existing ClickHouse and PostgreSQL driver registrations intact.

---

## File structure

- `server/drivers/bigquery/pom.xml`: Maven module that downloads BigQuery JDBC runtime dependencies to the distribution.
- `server/drivers/pom.xml`: Parent driver-module list.
- `server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml`: Resource mapping, driver bundle, and enabled BigQuery driver registration.
- `deploy/tests/verify-bigquery-packaging.sh`: Repeatable static assertion for the BigQuery packaging contract.
- `deploy/docker/cloudbeaver-ce/Dockerfile`: Root-context multi-stage Coolify build.
- `deploy/docker/cloudbeaver-ce/README.md`: Coolify deployment and UI-only credential setup guide.

### Task 1: Add a failing packaging-contract test

**Files:**
- Create: `deploy/tests/verify-bigquery-packaging.sh`
- Test: `deploy/tests/verify-bigquery-packaging.sh`

**Interfaces:**
- Consumes: repository root path as the script's current working directory.
- Produces: exit code `0` only when the BigQuery Maven module, resource mapping, bundle, and driver registration exist with the expected identifiers.

- [ ] **Step 1: Write the failing test**

Create an executable Bash script containing these assertions:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

grep -Fq '<module>bigquery</module>' server/drivers/pom.xml
grep -Fq '<artifactId>drivers.bigquery</artifactId>' server/drivers/bigquery/pom.xml
grep -Fq '<artifactId>google-cloud-bigquery-jdbc</artifactId>' server/drivers/bigquery/pom.xml
grep -Fq '<version>1.2.0</version>' server/drivers/bigquery/pom.xml
grep -Fq '<resource name="drivers/google-bigquery"/>' server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
grep -Fq '<bundle id="drivers.google-bigquery" label="Google BigQuery drivers"/>' server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
grep -Fq '<driver id="bigquery:google_bigquery_jdbc"/>' server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash deploy/tests/verify-bigquery-packaging.sh`

Expected: failure because `server/drivers/bigquery/pom.xml` does not exist.

- [ ] **Step 3: Do not add production configuration in this task**

Leave the script failing; the next task is the smallest production change that makes it pass.

- [ ] **Step 4: Commit the red test**

```bash
git add deploy/tests/verify-bigquery-packaging.sh
git commit -m "test: define BigQuery driver packaging contract"
```

### Task 2: Bundle and register the BigQuery JDBC driver

**Files:**
- Create: `server/drivers/bigquery/pom.xml`
- Modify: `server/drivers/pom.xml`
- Modify: `server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml`
- Test: `deploy/tests/verify-bigquery-packaging.sh`

**Interfaces:**
- Consumes: `drivers` parent Maven dependency-copy execution and the DBeaver platform's `bigquery:google_bigquery_jdbc` extension.
- Produces: JARs under `deploy/drivers/google-bigquery`; a visible BigQuery driver in CloudBeaver's connection wizard.

- [ ] **Step 1: Add the Maven module**

Create `server/drivers/bigquery/pom.xml` using the existing PostgreSQL module pattern. Set `artifactId` to `drivers.bigquery`, set `deps.output.dir` to `google-bigquery`, and include exactly:

```xml
<dependency>
    <groupId>com.google.cloud</groupId>
    <artifactId>google-cloud-bigquery-jdbc</artifactId>
    <version>1.2.0</version>
</dependency>
```

- [ ] **Step 2: Register the Maven module**

Add `<module>bigquery</module>` to the `server/drivers/pom.xml` module list, adjacent to the other database driver modules.

- [ ] **Step 3: Register the runtime bundle and driver**

In `server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml`, add:

```xml
<resource name="drivers/google-bigquery"/>
<bundle id="drivers.google-bigquery" label="Google BigQuery drivers"/>
<driver id="bigquery:google_bigquery_jdbc"/>
```

Place each entry in its matching extension block without removing existing entries.

- [ ] **Step 4: Run the contract test to verify it passes**

Run: `bash deploy/tests/verify-bigquery-packaging.sh`

Expected: exit code `0`.

- [ ] **Step 5: Build the driver module**

Run from `server/drivers`: `mvn -pl bigquery package`

Expected: Maven resolves `google-cloud-bigquery-jdbc:1.2.0` and creates artifacts in `deploy/drivers/google-bigquery`.

- [ ] **Step 6: Commit the driver integration**

```bash
git add server/drivers/bigquery/pom.xml server/drivers/pom.xml server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
git commit -m "feat: add BigQuery JDBC driver"
```

### Task 3: Make the Docker image build directly from Git source

**Files:**
- Modify: `deploy/docker/cloudbeaver-ce/Dockerfile`
- Modify: `deploy/tests/verify-bigquery-packaging.sh`
- Test: `deploy/tests/verify-bigquery-packaging.sh`

**Interfaces:**
- Consumes: repository root as Docker build context and `deploy/build.sh` as the project build entry point.
- Produces: image filesystem rooted at `/opt/cloudbeaver` with generated server, web assets, bundled drivers, and the existing launcher.

- [ ] **Step 1: Extend the failing test for Docker build stages**

Append assertions that require the Dockerfile to copy the source to a builder stage, run `./build.sh`, and copy `/workspace/cloudbeaver/deploy/cloudbeaver` from that stage:

```bash
grep -Fq 'FROM node:24.13.1-bookworm AS builder' deploy/docker/cloudbeaver-ce/Dockerfile
grep -Fq 'COPY . /workspace/cloudbeaver' deploy/docker/cloudbeaver-ce/Dockerfile
grep -Fq 'RUN ./build.sh' deploy/docker/cloudbeaver-ce/Dockerfile
grep -Fq 'COPY --from=builder /workspace/cloudbeaver/deploy/cloudbeaver /opt/cloudbeaver' deploy/docker/cloudbeaver-ce/Dockerfile
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash deploy/tests/verify-bigquery-packaging.sh`

Expected: failure because the current Dockerfile has no builder stage.

- [ ] **Step 3: Replace the packaging-only Dockerfile**

Use `node:24.13.1-bookworm` as `builder`. Copy Temurin Java 21 from `eclipse-temurin:21-jdk-noble`, install Git, curl, and Maven 3.9.11, enable Corepack, copy the repository to `/workspace/cloudbeaver`, clone `dbeaver-common` and `dbeaver` into `/workspace`, and run `/workspace/cloudbeaver/deploy/build.sh`.

Use `dbeaver/base-java:${BASE_JAVA_TAG}` as the runtime stage. Preserve UID/GID 8978, copy the generated distribution and launcher from `builder`, set directory mode and ownership, expose port 8978, and retain the existing entrypoint.

- [ ] **Step 4: Run the static test to verify it passes**

Run: `bash deploy/tests/verify-bigquery-packaging.sh`

Expected: exit code `0`.

- [ ] **Step 5: Build the image from repository root**

Run: `docker build --file deploy/docker/cloudbeaver-ce/Dockerfile --tag cloudbeaver-bigquery:local .`

Expected: successful build with no credential files copied into any stage.

- [ ] **Step 6: Commit the container build**

```bash
git add deploy/docker/cloudbeaver-ce/Dockerfile deploy/tests/verify-bigquery-packaging.sh
git commit -m "feat: build CloudBeaver image from source"
```

### Task 4: Document Coolify deployment and manual BigQuery credential entry

**Files:**
- Create: `deploy/docker/cloudbeaver-ce/README.md`
- Test: `deploy/tests/verify-bigquery-packaging.sh`

**Interfaces:**
- Consumes: Coolify repository-root build context, Dockerfile path, port 8978, and a persistent workspace volume.
- Produces: operator instructions for creating a BigQuery connection without committing a secret.

- [ ] **Step 1: Extend the failing test for documentation requirements**

Append these assertions:

```bash
grep -Fq 'deploy/docker/cloudbeaver-ce/Dockerfile' deploy/docker/cloudbeaver-ce/README.md
grep -Fq '/opt/cloudbeaver/workspace' deploy/docker/cloudbeaver-ce/README.md
grep -Fq 'OAuthType' deploy/docker/cloudbeaver-ce/README.md
grep -Fq 'OAuthPvtKey' deploy/docker/cloudbeaver-ce/README.md
grep -Fq 'Never commit the JSON key' deploy/docker/cloudbeaver-ce/README.md
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash deploy/tests/verify-bigquery-packaging.sh`

Expected: failure because the README does not exist.

- [ ] **Step 3: Write the operator guide**

Document these exact steps: set Coolify's Dockerfile path to
`deploy/docker/cloudbeaver-ce/Dockerfile`; use the repository root as build
context; publish port 8978; mount persistent storage at
`/opt/cloudbeaver/workspace`; create a connection in the UI; select Google
BigQuery; set the project ID; set `OAuthType` to `0`; paste the service-account
JSON into `OAuthPvtKey`; test and save. Include the sentence: `Never commit
the JSON key.`

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash deploy/tests/verify-bigquery-packaging.sh`

Expected: exit code `0`.

- [ ] **Step 5: Commit the documentation**

```bash
git add deploy/docker/cloudbeaver-ce/README.md deploy/tests/verify-bigquery-packaging.sh
git commit -m "docs: describe Coolify BigQuery deployment"
```

### Task 5: Verify the complete image contract

**Files:**
- Test: `deploy/tests/verify-bigquery-packaging.sh`

**Interfaces:**
- Consumes: `cloudbeaver-bigquery:local` built in Task 3.
- Produces: evidence that the image contains each expected JDBC driver directory and uses no baked credential JSON.

- [ ] **Step 1: Run static contract validation**

Run: `bash deploy/tests/verify-bigquery-packaging.sh`

Expected: exit code `0`.

- [ ] **Step 2: Inspect the built image's driver directories**

Run:

```bash
docker run --rm --entrypoint sh cloudbeaver-bigquery:local -c '
  test -d /opt/cloudbeaver/drivers/google-bigquery &&
  test -d /opt/cloudbeaver/drivers/clickhouse_com &&
  test -d /opt/cloudbeaver/drivers/postgresql &&
  ! find /opt/cloudbeaver -type f -name "*.json" | grep -q .
'
```

Expected: exit code `0`.

- [ ] **Step 3: Inspect the image startup contract**

Run: `docker inspect cloudbeaver-bigquery:local --format '{{json .Config.Entrypoint}}'`

Expected: `["./launch-product.sh"]`.

- [ ] **Step 4: Commit no additional changes**

The previous tasks already commit all code and documentation. Confirm a clean
working tree with `git status --short`.
