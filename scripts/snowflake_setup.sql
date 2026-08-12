-- Compute engine for this project. XSMALL is enough for our data volume;
-- AUTO_SUSPEND=60 minimizes idle credit consumption.
CREATE WAREHOUSE AIR_TRAFFIC_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE AIR_TRAFFIC;

-- Landing layer for unparsed source data. staging/intermediate/marts
-- schemas will be created automatically by dbt later.
CREATE SCHEMA AIR_TRAFFIC.RAW;

-- Least-privilege role used only by the ingestion pipeline.
CREATE ROLE LOADER;
GRANT USAGE ON WAREHOUSE AIR_TRAFFIC_WH TO ROLE LOADER;
GRANT USAGE ON DATABASE AIR_TRAFFIC TO ROLE LOADER;
GRANT USAGE ON SCHEMA AIR_TRAFFIC.RAW TO ROLE LOADER;
GRANT CREATE TABLE ON SCHEMA AIR_TRAFFIC.RAW TO ROLE LOADER;

-- Service account for the Python ingestion scripts, authenticated by key
-- pair (no password). Public key is not secret, but kept as a placeholder
-- here since it goes stale the moment the key is rotated.
CREATE USER SVC_LOADER
  TYPE = SERVICE
  RSA_PUBLIC_KEY = '<PASTE_CURRENT_PUBLIC_KEY_HERE>'
  DEFAULT_ROLE = LOADER
  DEFAULT_WAREHOUSE = AIR_TRAFFIC_WH
  COMMENT = 'Service account used by the ingestion pipeline (GitHub Actions)';

GRANT ROLE LOADER TO USER SVC_LOADER;

-- Raw landing tables: one API poll per row, not yet parsed.
CREATE TABLE AIR_TRAFFIC.RAW.OPENSKY_TABLE (
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_zone STRING,
    raw_payload VARIANT
);

CREATE TABLE AIR_TRAFFIC.RAW.WEATHER_TABLE (
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_zone STRING,
    raw_payload VARIANT
);

-- LOADER owns neither table (created manually under ACCOUNTADMIN), so
-- INSERT must be granted explicitly.
GRANT INSERT ON TABLE AIR_TRAFFIC.RAW.OPENSKY_TABLE TO ROLE LOADER;
GRANT INSERT ON TABLE AIR_TRAFFIC.RAW.WEATHER_TABLE TO ROLE LOADER;