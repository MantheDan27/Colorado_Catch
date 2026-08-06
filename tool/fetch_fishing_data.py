#!/usr/bin/env python3
"""One-off script to bake Colorado Parks & Wildlife (CPW) Fishing Atlas data
into a static GeoJSON asset (assets/data/colorado_fishing_areas.geojson) that
ships with the app, instead of hitting CPW's live ArcGIS service at runtime.

Data source: CPW's public ArcGIS Server, discovered via the "Colorado Fishing
Atlas" web map on arcgis.com (item 97caf952a158440097ec07c620d55777):
  https://ndismaps.nrel.colostate.edu/arcgis/rest/services/FishingAtlas2025/FishingInfo2025/MapServer

Re-run this whenever the baked data should be refreshed:
  python3 tool/fetch_fishing_data.py

Requires only the standard library (urllib/json) — no extra deps to install.
"""
import json
import urllib.request
from pathlib import Path

BASE = (
    "https://ndismaps.nrel.colostate.edu/arcgis/rest/services/"
    "FishingAtlas2025/FishingInfo2025/MapServer"
)

# (layer id, category, name field, subtitle builder)
LAYERS = [
    (7, "fishing_water", None, None),   # Fishing locations: streams/rivers + water bodies (points)
    (34, "gold_medal_stream", "WATERNAME", None),  # Gold Medal Streams (polylines)
    (35, "gold_medal_lake", "NAME", None),          # Gold Medal Lakes (polygons)
    (8, "boat_ramp", "FeatureName", None),          # Boat ramps (points)
    (0, "accessible_area", None, None),             # Accessible fishing areas (points)
]

OUT_PATH = Path(__file__).resolve().parent.parent / "assets" / "data" / "colorado_fishing_areas.geojson"


def fetch_layer(layer_id: str) -> dict:
    url = f"{BASE}/{layer_id}/query?where=1%3D1&outFields=*&f=geojson"
    with urllib.request.urlopen(url, timeout=30) as resp:
        return json.load(resp)


def label_for(category: str, props: dict) -> str:
    if category == "fishing_water":
        name = props.get("FA_NAME2") or props.get("DOW_NAME") or "Unnamed water"
        loc_type = props.get("LOC_TYPE") or ""
        county = props.get("COUNTYNAME")
        subtitle = loc_type + (f" · {county} County" if county else "")
        return name, subtitle
    if category == "gold_medal_stream":
        return props.get("WATERNAME") or "Gold Medal stream", "Gold Medal Water"
    if category == "gold_medal_lake":
        return props.get("NAME") or props.get("DOW_NAME") or "Gold Medal lake", "Gold Medal Water"
    if category == "boat_ramp":
        return props.get("FeatureName") or "Boat ramp", props.get("Property") or "Boat ramp"
    if category == "accessible_area":
        return "Accessible fishing area", (props.get("NOTES") or "Wheelchair/mobility accessible")
    return "Unknown", ""


def main() -> None:
    features = []
    for layer_id, category, _name_field, _subtitle in LAYERS:
        print(f"Fetching layer {layer_id} ({category})...")
        data = fetch_layer(layer_id)
        for feature in data.get("features", []):
            props = feature.get("properties") or {}
            name, subtitle = label_for(category, props)
            features.append({
                "type": "Feature",
                "geometry": feature["geometry"],
                "properties": {
                    "category": category,
                    "name": name,
                    "subtitle": subtitle,
                },
            })
        print(f"  -> {len(data.get('features', []))} features")

    out = {"type": "FeatureCollection", "features": features}
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(out))
    print(f"Wrote {len(features)} features to {OUT_PATH}")


if __name__ == "__main__":
    main()
