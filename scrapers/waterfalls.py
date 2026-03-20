"""
High Country Outdoors — Waterfalls Scraper Module
==================================================
Handles three data pipelines:

  1. OSM Overpass  — waterfall seed data (name, lat/lon, height)
  2. USGS IV/Stats — live stream flow + percentile-based flow_status
  3. Open-Meteo   — 7-day precipitation fallback when no USGS gauge
  4. NPS API      — trail closure alerts (reuses existing nps.py helpers)

Usage:
  Imported by waterfall_scraper.py (standalone) and optionally called
  from scraper.py with --waterfalls flag.

  USGS IV API:   https://waterservices.usgs.gov/nwis/iv/
  USGS Stats:    https://waterservices.usgs.gov/nwis/stat/
  OSM Overpass:  https://overpass-api.de/api/interpreter
  Open-Meteo:    https://api.open-meteo.com/v1/forecast
"""

import json
import time
import requests
from datetime import datetime, timezone
from typing import Optional

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
USGS_IV_URL  = "https://waterservices.usgs.gov/nwis/iv/"
USGS_STAT_URL = "https://waterservices.usgs.gov/nwis/stat/"
OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

# NC High Country bounding box: (south, west, north, east)
DEFAULT_BBOX = (35.4, -82.0, 36.7, -80.5)

# Precipitation thresholds (inches over 7 days)
PRECIP_DRY_IN    = 0.5
PRECIP_WET_IN    = 2.0

# NPS park codes to check for waterfall-adjacent closures
WATERFALL_NPS_CODES = ["blri", "appa"]


# ---------------------------------------------------------------------------
# 1. OSM Overpass — seed waterfall locations
# ---------------------------------------------------------------------------

def fetch_osm_waterfalls(bbox: tuple = DEFAULT_BBOX) -> list[dict]:
    """
    Query OSM Overpass API for waterway=waterfall nodes/ways in bbox.
    Returns a list of dicts with: osm_id, name, lat, lon, height_m, source.
    """
    south, west, north, east = bbox
    query = f"""
[out:json][timeout:30];
(
  node["waterway"="waterfall"]({south},{west},{north},{east});
  way["waterway"="waterfall"]({south},{west},{north},{east});
  relation["waterway"="waterfall"]({south},{west},{north},{east});
);
out center tags;
"""
    try:
        resp = requests.post(OVERPASS_URL, data={"data": query}, timeout=35)
        resp.raise_for_status()
        elements = resp.json().get("elements", [])
        return [_parse_osm_element(e) for e in elements if _has_location(e)]
    except Exception as e:
        print(f"  OSM Overpass error: {e}")
        return []


def _has_location(element: dict) -> bool:
    if element.get("type") == "node":
        return "lat" in element and "lon" in element
    # ways/relations have a center
    return "center" in element


def _parse_osm_element(element: dict) -> dict:
    tags = element.get("tags", {})

    if element.get("type") == "node":
        lat = element["lat"]
        lon = element["lon"]
    else:
        lat = element["center"]["lat"]
        lon = element["center"]["lon"]

    name = (
        tags.get("name")
        or tags.get("name:en")
        or f"Waterfall {element['id']}"
    )

    # OSM stores height in meters (ele tag or height tag)
    height_m = None
    for tag in ("height", "ele"):
        raw = tags.get(tag, "")
        try:
            height_m = float(raw.replace("m", "").strip())
            break
        except (ValueError, AttributeError):
            pass

    height_ft = round(height_m * 3.28084) if height_m is not None else None

    return {
        "osm_id":   element["id"],
        "name":     name,
        "lat":      lat,
        "lon":      lon,
        "height_m": height_m,
        "height_ft": height_ft,
        "source":   "osm",
        "wikidata": tags.get("wikidata"),
        "wikipedia": tags.get("wikipedia"),
    }


def slug(name: str) -> str:
    """Convert waterfall name to a stable snake_case id."""
    import re
    s = name.lower().strip()
    s = re.sub(r"[^a-z0-9\s]", "", s)
    s = re.sub(r"\s+", "_", s)
    s = re.sub(r"_falls?$", "_falls", s)
    return s


def merge_osm_into_existing(osm_waterfalls: list[dict], existing: list[dict]) -> list[dict]:
    """
    Merge new OSM entries into the existing list.
    - Existing entries (matched by osm_id or name slug) are preserved.
    - New OSM entries are appended with default field values.
    - Manually-curated fields (usgs_gauge_id, nps_unit, difficulty, description)
      are never overwritten by OSM data.
    """
    existing_by_osm_id = {e.get("osm_id"): e for e in existing if e.get("osm_id")}
    existing_by_slug   = {slug(e["name"]): e for e in existing}
    updated = list(existing)

    for osm in osm_waterfalls:
        eid = osm["osm_id"]
        eslug = slug(osm["name"])

        # Match by osm_id first, then name slug
        if eid in existing_by_osm_id:
            entry = existing_by_osm_id[eid]
            # Update only coordinate/height from OSM (non-destructive)
            entry.setdefault("lat", osm["lat"])
            entry.setdefault("lon", osm["lon"])
            if entry.get("height_m") is None and osm.get("height_m"):
                entry["height_m"] = osm["height_m"]
                entry["height_ft"] = osm["height_ft"]
        elif eslug in existing_by_slug:
            entry = existing_by_slug[eslug]
            entry.setdefault("osm_id", eid)
        else:
            # Brand new entry — create with defaults
            new_entry = _default_waterfall(osm)
            updated.append(new_entry)
            existing_by_osm_id[eid] = new_entry
            existing_by_slug[eslug] = new_entry
            print(f"  + New waterfall from OSM: {osm['name']}")

    return updated


def _default_waterfall(osm: dict) -> dict:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        "id":                   slug(osm["name"]),
        "name":                 osm["name"],
        "lat":                  osm["lat"],
        "lon":                  osm["lon"],
        "height_ft":            osm.get("height_ft"),
        "height_m":             osm.get("height_m"),
        "difficulty":           "moderate",
        "trail_miles":          None,
        "county":               "",
        "state":                "NC",
        "usgs_gauge_id":        None,
        "nps_unit":             None,
        "source":               "osm",
        "osm_id":               osm["osm_id"],
        "description":          None,
        "flow_status":          "unknown",
        "flow_cfs":             None,
        "precip_7day_in":       None,
        "precip_status":        None,
        "trail_closed":         False,
        "closure_description":  None,
        "last_updated":         now,
    }


# ---------------------------------------------------------------------------
# 2. USGS — live flow + percentile stats
# ---------------------------------------------------------------------------

def fetch_usgs_flow(gauge_id: str) -> Optional[float]:
    """
    Fetch current streamflow (CFS) from USGS Instantaneous Values API.
    Returns CFS as float, or None on failure.
    """
    try:
        resp = requests.get(
            USGS_IV_URL,
            params={
                "format":      "json",
                "sites":       gauge_id,
                "parameterCd": "00060",
            },
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json()

        series = (
            data.get("value", {})
                .get("timeSeries", [])
        )
        for ts in series:
            values = ts.get("values", [{}])[0].get("value", [])
            if values:
                latest = values[-1].get("value")
                if latest is not None and latest != "-999999":
                    return float(latest)
    except Exception as e:
        print(f"    USGS flow error (gauge {gauge_id}): {e}")
    return None


def fetch_usgs_percentile_stats(gauge_id: str) -> Optional[dict]:
    """
    Fetch USGS statistics for percentile thresholds (p25, p75, p90).
    Returns dict with keys p25, p75, p90 as floats, or None.
    """
    try:
        resp = requests.get(
            USGS_STAT_URL,
            params={
                "format":      "json",
                "sites":       gauge_id,
                "parameterCd": "00060",
                "statType":    "P25,P75,P90",
            },
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json()

        time_series = data.get("value", {}).get("timeSeries", [])
        stats: dict[str, float] = {}

        for ts in time_series:
            stat_code = ts.get("variable", {}).get("variableCode", [{}])[0].get("value", "")
            for series_stat in ts.get("values", []):
                stat_desc = series_stat.get("qualifier", [{}])[0].get("qualifierDescription", "")
                values = series_stat.get("value", [])
                if values:
                    val = values[0].get("value")
                    if val is not None:
                        if "P25" in stat_desc or stat_desc == "P25":
                            stats["p25"] = float(val)
                        elif "P75" in stat_desc or stat_desc == "P75":
                            stats["p75"] = float(val)
                        elif "P90" in stat_desc or stat_desc == "P90":
                            stats["p90"] = float(val)

        # Alternative: parse from statisticsCd field
        for ts in time_series:
            for v in ts.get("values", []):
                for q in v.get("qualifier", []):
                    code = q.get("qualifierCode", "")
                    vals = v.get("value", [])
                    if not vals:
                        continue
                    try:
                        cfs = float(vals[0].get("value", "nan"))
                    except (ValueError, TypeError):
                        continue
                    if "P25" in code:
                        stats["p25"] = cfs
                    elif "P75" in code:
                        stats["p75"] = cfs
                    elif "P90" in code:
                        stats["p90"] = cfs

        return stats if stats else None

    except Exception as e:
        print(f"    USGS stats error (gauge {gauge_id}): {e}")
    return None


def compute_flow_status(current_cfs: float, stats: Optional[dict]) -> str:
    """
    Compute flow_status string from current CFS vs percentile thresholds.
    Falls back to 'unknown' if stats unavailable.
    """
    if stats is None:
        return "unknown"

    p25 = stats.get("p25")
    p75 = stats.get("p75")
    p90 = stats.get("p90")

    if p25 is None or p75 is None:
        return "unknown"

    if current_cfs < p25:
        return "low"
    elif current_cfs <= p75:
        return "normal"
    elif p90 is not None and current_cfs <= p90:
        return "high"
    else:
        return "flood"


# ---------------------------------------------------------------------------
# 3. Open-Meteo — 7-day precipitation fallback
# ---------------------------------------------------------------------------

def fetch_precip_7day(lat: float, lon: float) -> Optional[float]:
    """
    Fetch 7-day total precipitation (inches) from Open-Meteo.
    Returns total inches, or None on failure.
    """
    try:
        resp = requests.get(
            OPEN_METEO_URL,
            params={
                "latitude":          lat,
                "longitude":         lon,
                "daily":             "precipitation_sum",
                "precipitation_unit": "inch",
                "timezone":          "America/New_York",
                "past_days":         7,
                "forecast_days":     1,
            },
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json()
        precip_list = data.get("daily", {}).get("precipitation_sum", [])
        # Sum last 7 days only (index 0..6)
        total = sum(p for p in precip_list[:7] if p is not None)
        return round(total, 2)
    except Exception as e:
        print(f"    Open-Meteo error at ({lat},{lon}): {e}")
    return None


def compute_precip_status(precip_in: Optional[float]) -> str:
    if precip_in is None:
        return "normal"
    if precip_in < PRECIP_DRY_IN:
        return "dry"
    elif precip_in <= PRECIP_WET_IN:
        return "normal"
    else:
        return "wet"


# ---------------------------------------------------------------------------
# 4. NPS closures for waterfalls
# ---------------------------------------------------------------------------

def apply_nps_closures_to_waterfalls(
    waterfalls: list[dict],
    nps_alerts: dict[str, list[dict]],
) -> list[dict]:
    """
    Apply NPS closure alerts to waterfalls matching their nps_unit field.
    Sets trail_closed=True and closure_description on affected waterfalls.
    Clears stale auto-closures before applying fresh data.
    """
    updated = []
    for wf in waterfalls:
        if wf.get("locked"):
            updated.append(wf)
            continue

        nps_unit = (wf.get("nps_unit") or "").lower()
        if not nps_unit or nps_unit not in nps_alerts:
            # Clear any previously auto-set closure
            wf["trail_closed"] = False
            wf["closure_description"] = None
            updated.append(wf)
            continue

        alerts = nps_alerts[nps_unit]
        closure_alerts = [
            a for a in alerts
            if "closure" in (a.get("category") or "").lower()
            or "closed" in (a.get("title") or "").lower()
        ]

        if closure_alerts:
            wf["trail_closed"] = True
            wf["closure_description"] = closure_alerts[0].get("description") or closure_alerts[0].get("title")
        else:
            wf["trail_closed"] = False
            wf["closure_description"] = None

        updated.append(wf)

    return updated


# ---------------------------------------------------------------------------
# 5. Main update function
# ---------------------------------------------------------------------------

def update_waterfall(wf: dict, pause_between_requests: float = 0.3) -> dict:
    """
    Update a single waterfall's live fields:
      - flow_status, flow_cfs via USGS (if usgs_gauge_id present)
      - precip_7day_in, precip_status via Open-Meteo (always)
      - last_updated timestamp

    Does NOT modify: id, name, lat, lon, height_*, difficulty,
    trail_miles, county, state, usgs_gauge_id, nps_unit, source,
    osm_id, description, trail_closed, closure_description (those
    come from seed + NPS pass).
    """
    if wf.get("locked"):
        return wf

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    gauge_id = wf.get("usgs_gauge_id")

    # --- USGS flow ---
    if gauge_id:
        cfs = fetch_usgs_flow(gauge_id)
        if cfs is not None:
            stats = fetch_usgs_percentile_stats(gauge_id)
            wf["flow_cfs"]    = round(cfs, 1)
            wf["flow_status"] = compute_flow_status(cfs, stats)
            print(f"    USGS {gauge_id}: {cfs:.0f} CFS → {wf['flow_status']}")
        else:
            wf["flow_status"] = "unknown"
            wf["flow_cfs"]    = None
        time.sleep(pause_between_requests)
    else:
        wf["flow_status"] = "unknown"
        wf["flow_cfs"]    = None

    # --- Open-Meteo precip (always — fallback indicator) ---
    lat = wf.get("lat")
    lon = wf.get("lon")
    if lat and lon:
        precip = fetch_precip_7day(lat, lon)
        wf["precip_7day_in"] = precip
        wf["precip_status"]  = compute_precip_status(precip)
        # If no USGS gauge, derive a rough flow_status from precip
        if not gauge_id and precip is not None:
            if precip < PRECIP_DRY_IN:
                wf["flow_status"] = "low"
            elif precip > PRECIP_WET_IN * 2:
                wf["flow_status"] = "high"
            else:
                wf["flow_status"] = "normal"
        time.sleep(pause_between_requests)

    wf["last_updated"] = now
    return wf
