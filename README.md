# Snowflake Air Traffic Analytics

Real-time air traffic analytics on Snowflake + dbt — combining live flight
data (OpenSky Network) and weather data (Open-Meteo) to track patterns
around Luxembourg, Frankfurt, Zurich, and Geneva.

## Business Question

Luxembourg's airport (Findel) is the global hub of Cargolux, one of the
world's largest all-cargo airlines. Frankfurt is Europe's busiest cargo
airport, home to Lufthansa Cargo. Zurich and Geneva, by contrast, are
large, mostly-passenger hubs. This project asks: how does live air traffic
behave across these four airports — in volume, timing, and airline mix —
and how does the cargo-heavy traffic at Luxembourg and Frankfurt compare to
the passenger-heavy traffic at Zurich and Geneva?

## Architecture

OpenSky API ─┐
├─> GitHub Actions (scheduled, every 15 min)
Open-Meteo ──┘ │
v
Snowflake RAW layer (VARIANT, semi-structured)
│
v
dbt staging (flatten + type)
│
v
dbt intermediate (sessionize pings into visits,
│ join nearest-time weather)
v
dbt marts (fct_airport_visits,
│ agg_airport_traffic_by_hour)
v
Streamlit in Snowflake dashboard


**Ingestion** — Python scripts poll OpenSky (OAuth2 client-credentials) and
Open-Meteo, writing raw JSON responses into Snowflake landing tables.
Scheduled via GitHub Actions every 15 minutes.

**Transformation (dbt)** — staging flattens each source's raw JSON into
typed columns; intermediate models group raw position pings into discrete
airport "visits" (window functions, incremental) and join them to the
nearest weather reading in time; marts expose the finished, queryable
answer to the business question.

**Governance** — least-privilege roles (`LOADER`, `TRANSFORMER`, `REPORTER`)
scoped to exactly what each identity needs, service accounts authenticated
by key pair rather than password, and a dynamic data masking policy that
hides aircraft identifiers for flights not matched to a known scheduled
airline — a real consideration given ongoing public debate over tracking
private aircraft by tail number.

**Delivery** — a Streamlit in Snowflake dashboard, owned by the read-only
`REPORTER` role, so it inherits the same restricted access as any other
consumer of the marts layer.

## Tech Stack

- **Snowflake** — warehouses, RBAC, dynamic data masking, dynamic tables,
  zero-copy cloning, Time Travel
- **dbt-snowflake** — staging / intermediate / marts modeling, incremental
  models, seeds
- **Python** — ingestion (`requests`, `snowflake-connector-python`,
  key-pair authentication)
- **GitHub Actions** — scheduled ingestion, secrets management
- **Streamlit in Snowflake** — dashboard

## Notable Design Decisions

- **Incremental only where it's needed.** Most dbt models are plain views
  or tables, rebuilt in full on every run — simple and safe while the
  logic was still changing. Only `stg_opensky`, the one model with real
  ingestion volume, is incremental.
- **Dynamic Table over a hand-built Stream + Task.** The hourly traffic
  aggregate uses Snowflake's declarative Dynamic Tables rather than a
  manually orchestrated Stream/Task pair, avoiding a redundant second
  mechanism alongside dbt's own incremental logic.
- **A masking policy with an actual rationale**, not just a demo for its
  own sake: aircraft that don't match a known airline callsign prefix are
  very likely private or business jets, a real privacy-sensitive category
  in the ADS-B tracking community.

## Project Structure

├── models/
│ ├── staging/ # 1 model per source, flatten + type
│ ├── intermediate/ # sessionization, nearest-time weather join
│ └── marts/ # fct_airport_visits, agg_airport_traffic_by_hour
├── seeds/ # airline_reference.csv
├── scripts/
│ ├── ingest_opensky.py
│ ├── ingest_weather.py
│ └── snowflake_setup.sql
├── streamlit/
│ └── streamlit_app.py
└── .github/workflows/
├── ingest.yml # scheduled ingestion (cron, every 15 min)
└── docs.yml # dbt docs generation + GitHub Pages publishing