"""Ingest live aircraft state vectors from OpenSky into AIR_TRAFFIC.RAW.OPENSKY_TABLE."""

import json
import os

import requests
import snowflake.connector
from dotenv import load_dotenv

load_dotenv()

TOKEN_URL = "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token"
STATES_URL = "https://opensky-network.org/api/states/all"

# Approximate bounding boxes (lamin, lamax, lomin, lomax) around each airport
ZONES = {
    "LUXEMBOURG": {"lamin": 49.35, "lamax": 49.90, "lomin": 5.75, "lomax": 6.75},
    "FRANKFURT":  {"lamin": 49.75, "lamax": 50.35, "lomin": 8.05, "lomax": 9.10},
    "ZURICH":     {"lamin": 47.15, "lamax": 47.75, "lomin": 8.05, "lomax": 9.05},
    "GENEVA":     {"lamin": 45.95, "lamax": 46.55, "lomin": 5.60, "lomax": 6.60},
}


def get_opensky_token() -> str:
    """Exchange client_id/client_secret for a short-lived (30 min) access token."""
    response = requests.post(
        TOKEN_URL,
        data={
            "grant_type": "client_credentials",
            "client_id": os.environ["OPENSKY_CLIENT_ID"],
            "client_secret": os.environ["OPENSKY_CLIENT_SECRET"],
        },
    )
    response.raise_for_status()
    return response.json()["access_token"]


def fetch_states(token: str, bbox: dict) -> dict:
    """Fetch current aircraft state vectors within a bounding box."""
    response = requests.get(
        STATES_URL,
        headers={"Authorization": f"Bearer {token}"},
        params=bbox,
    )
    response.raise_for_status()
    return response.json()


def get_snowflake_connection():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user="SVC_LOADER",
        role="LOADER",
        warehouse="AIR_TRAFFIC_WH",
        database="AIR_TRAFFIC",
        schema="RAW",
        private_key_file=os.environ["SNOWFLAKE_PRIVATE_KEY_PATH"],
        private_key_file_pwd=None,  # key was generated without a passphrase
    )


def insert_raw(conn, source_zone: str, payload: dict) -> None:
    conn.cursor().execute(
        "INSERT INTO OPENSKY_TABLE (source_zone, raw_payload) SELECT %s, PARSE_JSON(%s)",
        (source_zone, json.dumps(payload)),
    )


def main():
    token = get_opensky_token()
    conn = get_snowflake_connection()
    try:
        for zone_name, bbox in ZONES.items():
            payload = fetch_states(token, bbox)
            insert_raw(conn, zone_name, payload)
            print(f"Inserted 1 row for {zone_name}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()