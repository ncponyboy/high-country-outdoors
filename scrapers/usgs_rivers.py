#!/usr/bin/env python3
"""
USGS River Conditions Scraper
Reads base river data from rivers.json, fetches live CFS and gauge height
from the USGS Water Resources API, then writes the enriched data back.

Usage:
    python scrapers/usgs_rivers.py

Requires: requests (pip install requests)
"""

import json
import os
import requests
from datetime import datetime, timezone

# USGS parameter codes
PARAM_CFS   = "00060"   # Discharge (CFS)
PARAM_GAUGE = "00065"   # Gage height (ft)

# Path to rivers.json — two levels up from this script (repo root)
REPO_ROOT  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RIVERS_PATH = os.path.join(REPO_ROOT, "rivers.json")


# ---------------------------------------------------------------------------
# USGS fetch
# ---------------------------------------------------------------------------

def fetch_usgs(site_ids: list[str]) -> dict:
    """
    Fetch latest instantaneous values from USGS Water Resources API.
    Returns dict keyed by site_no -> {cfs, gauge_ft, trend}.
    """
    sites_str = ",".join(site_ids)
    url = (
        "https://waterservices.usgs.gov/nwis/iv/"
        f"?format=json&sites={sites_str}"
        f"&parameterCd={PARAM_CFS},{PARAM_GAUGE}"
        "&siteStatus=active"
        "&period=PT3H"
    )

    try:
        resp = requests.get(url, timeout=20)
        resp.raise_for_status()
        data = resp.json()
    except Exception as e:
        print(f"[ERROR] USGS API request failed: {e}")
        return {}

    results = {}

    try:
        time_series = data["value"]["timeSeries"]
    except (KeyError, TypeError):
        print("[ERROR] Unexpected USGS response structure")
        return {}

    for series in time_series:
        try:
            site_no  = series["sourceInfo"]["siteCode"][0]["value"]
            param_cd = series["variable"]["variableCode"][0]["value"]
            values   = series["values"][0]["value"]
        except (KeyError, IndexError, TypeError):
            continue

        if not values:
            continue

        # Latest non-null value
        latest_val = None
        for v in reversed(values):
            try:
                f = float(v["value"])
                if f >= 0:
                    latest_val = f
                    break
            except (ValueError, TypeError):
                continue

        if latest_val is None:
            continue

        if site_no not in results:
            results[site_no] = {}

        if param_cd == PARAM_CFS:
            results[site_no]["cfs"] = latest_val
            # Trend from last 3 readable values
            readable = []
            for v in values:
                try:
                    readable.append(float(v["value"]))
                except (ValueError, TypeError):
                    pass
            if len(readable) >= 3:
                diff = readable[-1] - readable[-3]
                threshold = readable[-1] * 0.05
                if diff > threshold:
                    results[site_no]["trend"] = "rising"
                elif diff < -threshold:
                    results[site_no]["trend"] = "falling"
                else:
                    results[site_no]["trend"] = "steady"
            else:
                results[site_no]["trend"] = "unknown"

        elif param_cd == PARAM_GAUGE:
            results[site_no]["gauge_ft"] = latest_val

    return results


# ---------------------------------------------------------------------------
# Condition label from CFS thresholds stored in rivers.json
# ---------------------------------------------------------------------------

def cfs_to_condition(cfs: float, river: dict) -> str:
    low_thresh   = river.get("optimal_cfs_low",   0)
    high_thresh  = river.get("optimal_cfs_high",  low_thresh * 4)
    flood_thresh = river.get("flood_cfs_threshold", high_thresh * 3)

    if cfs < low_thresh:
        return "low"
    elif cfs <= high_thresh:
        return "optimal"
    elif cfs < flood_thresh:
        return "high"
    else:
        return "flood"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("Loading rivers.json...")
    with open(RIVERS_PATH) as f:
        data = json.load(f)

    rivers = data.get("rivers", [])
    if not rivers:
        print("[ERROR] No rivers found in rivers.json")
        return

    site_ids = [r["usgs_gauge_id"] for r in rivers if r.get("usgs_gauge_id")]
    print(f"Fetching USGS data for {len(site_ids)} gauges...")
    usgs_data = fetch_usgs(site_ids)

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    for river in rivers:
        gauge_id   = river.get("usgs_gauge_id")
        gauge_data = usgs_data.get(gauge_id, {}) if gauge_id else {}

        cfs      = gauge_data.get("cfs")
        gauge_ft = gauge_data.get("gauge_ft")
        trend    = gauge_data.get("trend", "unknown")
        condition = cfs_to_condition(cfs, river) if cfs is not None else "unknown"

        # Inject / overwrite live fields only
        river["current_cfs"]   = round(cfs, 1)      if cfs      is not None else None
        river["gauge_ft"]      = round(gauge_ft, 2) if gauge_ft is not None else None
        river["trend"]         = trend
        river["condition"]     = condition
        river["last_updated"]  = now if cfs is not None else ""

        status = f"{cfs:.0f} cfs" if cfs is not None else "NO DATA"
        print(f"  {river['name']}: {status} ({condition}) trend={trend}")

    data["last_updated"] = now

    with open(RIVERS_PATH, "w") as f:
        json.dump(data, f, indent=2)

    print(f"\nUpdated {len(rivers)} rivers in {RIVERS_PATH}")


if __name__ == "__main__":
    main()
