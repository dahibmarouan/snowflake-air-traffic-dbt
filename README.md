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