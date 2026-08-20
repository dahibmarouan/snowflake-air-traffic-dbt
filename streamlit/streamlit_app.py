import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Air Traffic — LU/DE/CH", layout="wide")
st.title("Air Traffic Analytics — Luxembourg, Germany, Switzerland")

session = get_active_session()

st.subheader("Traffic by hour and zone")
traffic_df = session.table("AIR_TRAFFIC.MARTS.AGG_AIRPORT_TRAFFIC_BY_HOUR").to_pandas()
st.bar_chart(traffic_df, x="VISIT_HOUR", y="VISIT_COUNT", color="SOURCE_ZONE")

st.subheader("Cargo share by zone")
cargo_summary = (
    traffic_df.groupby("SOURCE_ZONE")[["VISIT_COUNT", "CARGO_VISIT_COUNT"]]
    .sum()
    .reset_index()
)
cargo_summary["CARGO_SHARE_PCT"] = round(
    100 * cargo_summary["CARGO_VISIT_COUNT"] / cargo_summary["VISIT_COUNT"], 1
)
st.dataframe(cargo_summary)

st.subheader("Recent visits")
visits_df = session.table("AIR_TRAFFIC.MARTS.FCT_AIRPORT_VISITS").to_pandas()
st.dataframe(visits_df.sort_values("VISIT_START", ascending=False).head(20))