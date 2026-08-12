"""Ingest current weather data from Open-Meteo into AIR_TRAFFIC.RAW.WEATHER_TABLE."""

import json
import os

import requests
import snowflake.connector
from dotenv import load_dotenv

load_dotenv()

WEATHER_URL = "https://api.open-meteo.com/v1/forecast"

# Airport coordinates (a single point per zone, unlike OpenSky's bounding boxes)
ZONES = {
    "LUXEMBOURG": {"latitude": 49.6233, "longitude": 6.2044},
    "FRANKFURT":  {"latitude": 50.0379, "longitude": 8.5622},
    "ZURICH":     {"latitude": 47.4647, "longitude": 8.5492},
    "GENEVA":     {"latitude": 46.2381, "longitude": 6.1090},
}


def fetch_weather(coords: dict) -> dict:
    params = {
        **coords,
        "current": "temperature_2m,wind_speed_10m,precipitation,cloud_cover,visibility",
    }
    response = requests.get(WEATHER_URL, params=params)
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
        private_key_file_pwd=None,
    )


def insert_raw(conn, source_zone: str, payload: dict) -> None:
    conn.cursor().execute(
        "INSERT INTO WEATHER_TABLE (source_zone, raw_payload) SELECT %s, PARSE_JSON(%s)",
        (source_zone, json.dumps(payload)),
    )


def main():
    conn = get_snowflake_connection()
    try:
        for zone_name, coords in ZONES.items():
            payload = fetch_weather(coords)
            insert_raw(conn, zone_name, payload)
            print(f"Inserted 1 row for {zone_name}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()