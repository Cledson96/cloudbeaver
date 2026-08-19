# CloudBeaver Community on Coolify

This image is built from the repository source and includes the Google BigQuery JDBC driver.

## Coolify configuration

- Set the Dockerfile path to `deploy/docker/cloudbeaver-ce/Dockerfile`.
- Use the repository root as the build context.
- Publish port `8978`.
- Add persistent storage mounted at `/opt/cloudbeaver/workspace`.

## Add a BigQuery connection

1. Open CloudBeaver and create a new connection.
2. Select **Google BigQuery** and the **BigQuery** driver.
3. Enter the Google Cloud project ID.
4. In the driver properties, set `OAuthType` to `0`.
5. Paste the complete service-account JSON into `OAuthPvtKey`.
6. Test and save the connection.

Never commit the JSON key. It is entered only in the CloudBeaver UI and is retained in the persistent workspace.
