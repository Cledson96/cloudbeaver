#!/usr/bin/env bash
set -Eeuo pipefail

grep -Fq '<module>bigquery</module>' server/drivers/pom.xml
grep -Fq '<artifactId>drivers.bigquery</artifactId>' server/drivers/bigquery/pom.xml
grep -Fq '<artifactId>google-cloud-bigquery-jdbc</artifactId>' server/drivers/bigquery/pom.xml
grep -Fq '<version>1.2.0</version>' server/drivers/bigquery/pom.xml
grep -Fq '<resource name="drivers/google-bigquery"/>' server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
grep -Fq '<bundle id="drivers.google-bigquery" label="Google BigQuery drivers"/>' server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
grep -Fq '<driver id="bigquery:google_bigquery_jdbc"/>' server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml
