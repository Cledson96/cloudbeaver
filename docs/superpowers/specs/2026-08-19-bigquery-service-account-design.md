# BigQuery Service Account Support Design

## Goal

Ship a CloudBeaver Community image that offers Google BigQuery alongside the
existing ClickHouse and PostgreSQL drivers. Administrators create BigQuery
connections in the CloudBeaver UI and enter their own Google service-account
JSON without putting credentials in this repository, the Dockerfile, or image
layers.

## Scope

- Bundle the official Google BigQuery JDBC driver version `1.2.0` in the
  CloudBeaver backend build.
- Register the existing DBeaver BigQuery provider and its current JDBC driver
  (`bigquery:google_bigquery_jdbc`) in the CloudBeaver Community driver
  registry.
- Package the JDBC dependency under `drivers/google-bigquery` in the built
  distribution so the server can load it without downloading files at runtime.
- Replace the current packaging-only Dockerfile with a multi-stage Dockerfile
  that builds the backend and frontend from this repository, then copies only
  the generated distribution to the runtime image.
- Preserve a writable `/opt/cloudbeaver/workspace` volume for CloudBeaver's
  persistent state and user-created connections.
- Provide deployment documentation for Coolify and an in-product BigQuery
  connection recipe.

## Non-goals

- Do not add a credential, project ID, or connection definition to source
  control.
- Do not expose a new public GraphQL API or create a custom frontend form for
  BigQuery credentials.
- Do not mount, bake, upload, or generate service-account JSON files during
  image build.
- Do not replace ClickHouse or PostgreSQL driver behavior.

## Architecture

CloudBeaver already builds JDBC driver archives as Maven modules in
`server/drivers` and describes visible driver bundles in
`io.cloudbeaver.resources.drivers.base`. A new `bigquery` Maven module will
download the official Google JDBC artifact and copy its runtime dependency set
to `deploy/drivers/google-bigquery`. The base driver resource plugin will map
that directory to the `drivers.google-bigquery` bundle and enable the existing
DBeaver BigQuery provider's `google_bigquery_jdbc` driver.

The build will continue to use the DBeaver platform source required by the
CloudBeaver Maven parent. The Docker builder stage will clone the matching
`dbeaver` and `dbeaver-common` platform repositories, build the CloudBeaver
backend, build the React frontend, and produce `deploy/cloudbeaver`. The
runtime stage will copy that directory into the existing Java base image and
run the existing launcher as the non-root `dbeaver` user.

## Driver and connection behavior

The enabled driver is the Google JDBC driver supplied by the DBeaver BigQuery
extension, not the legacy Simba driver. It uses the BigQuery provider ID
`bigquery` and driver ID `google_bigquery_jdbc`.

After deployment, an administrator creates a connection in the CloudBeaver UI:

1. Select **Google BigQuery** and the **BigQuery** driver.
2. Enter the Google Cloud project ID as the database/project.
3. In the driver properties, enter `OAuthType` as `0`.
4. Enter the entire service-account key JSON in `OAuthPvtKey`.
5. Test and save the connection.

`OAuthType=0` is the Google JDBC driver's service-account mode.
`OAuthPvtKey` accepts a raw service-account JSON object. The value is entered
only by the administrator in the running application and is never placed in
the codebase or Docker build context.

The connection is saved in CloudBeaver's workspace. The deployment must retain
`/opt/cloudbeaver/workspace` using Coolify persistent storage. Because this
state contains connection credentials, access to the application, its backing
volume, and backups must be restricted to authorized operators.

## Docker build and runtime

The repository's existing Dockerfile only copies an already-generated
`cloudbeaver` directory, so it cannot be used by Coolify to build directly
from a fresh Git checkout. The new multi-stage Dockerfile will have these
stages:

1. **Builder:** install the Java, Maven, Node.js, Corepack, Git, and shell
   tools required by the existing build scripts; clone the DBeaver platform
   siblings; run the backend and frontend build commands.
2. **Runtime:** retain `dbeaver/base-java`, create the `dbeaver` UID/GID 8978
   account, copy only `deploy/cloudbeaver`, set ownership and executable bits,
   expose port 8978, and launch `launch-product.sh`.

The image contains the BigQuery JDBC artifacts but no BigQuery connection or
credential. Coolify must build from repository root with
`deploy/docker/cloudbeaver-ce/Dockerfile` as the Dockerfile path and attach a
persistent volume at `/opt/cloudbeaver/workspace`.

## Failure handling

- A failed image build must fail before publishing an image; it must not fall
  back to the old prebuilt-directory Dockerfile behavior.
- Missing or invalid BigQuery credentials must fail the CloudBeaver connection
  test without affecting existing datasource connections.
- The application must surface the Google JDBC driver's error and must not log
  the JSON credential value.
- The persistent workspace must remain writable by UID/GID 8978 so connection
  changes survive container restarts.

## Verification

- Add focused tests or static build assertions for the new driver module and
  resource registry entries before changing production configuration.
- Build the backend and confirm the distribution contains
  `drivers/google-bigquery` with the Google JDBC driver artifact.
- Build the frontend with the repository's existing Yarn commands.
- Build the Docker image from repository root using the multi-stage Dockerfile.
- Start the resulting container with a mounted workspace, confirm the setup
  wizard loads, and confirm **Google BigQuery** appears in the new-connection
  driver list.
- Confirm the existing ClickHouse and PostgreSQL drivers remain registered and
  are still present in the final distribution.

## References

- CloudBeaver driver integration guide:
  <https://github.com/dbeaver/cloudbeaver/wiki/Adding-new-database-drivers>
- Google BigQuery JDBC authentication reference:
  <https://docs.cloud.google.com/bigquery/docs/jdbc-for-bigquery?hl=pt-br>
