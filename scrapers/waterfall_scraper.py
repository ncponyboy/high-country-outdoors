#!/usr/bin/env python3
"""
High Country Outdoors — Waterfall Scraper
==========================================
Standalone entry point for the waterfall data pipeline.

Two phases:
  --seed   Query OSM Overpass and merge new waterfalls into waterfalls.json
  --update Refresh live flow, precipitation, and NPS closure data (default)

Both phases can run together. The --update phase runs by default even without
--seed so GitHub Actions can run it on a schedule (e.g. every 6 hours).

Usage:
  # Full run (seed + update, requires NPS key):
  python waterfall_scraper.py --seed --nps-key YOUR_KEY

  # Live data update only (no OSM re-scrape):
  python waterfall_scraper.py --nps-key YOUR_KEY

  # Seed only, skip live data:
  python waterfall_scraper.py --seed --skip-update

  # Development / testing:
  python waterfall_scraper.py --skip-nps --skip-precip

Environment variables:
  NPS_API_KEY  — NPS developer API key (free at nps.gov/subjects/developer)
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# Ensure scraper module directory is on path when run directly
sys.path.insert(0, str(Path(__file__).parent))

from waterfalls import (
    fetch_osm_waterfalls,
    merge_osm_into_existing,
    update_waterfall,
    apply_nps_closures_to_waterfalls,
    DEFAULT_BBOX,
)
from nps import fetch_nps_alerts

REPO_ROOT    = Path(__file__).resolve().parent.parent
JSON_PATH    = REPO_ROOT / "waterfalls.json"
COUNTS_PATH  = REPO_ROOT / "waterfall_source_counts.json"


# ---------------------------------------------------------------------------
# I/O helpers
# ---------------------------------------------------------------------------

def load_waterfalls() -> list[dict]:
    if not JSON_PATH.exists():
        print(f"  ⚠️  {JSON_PATH} not found — starting from empty list")
        return []
    with open(JSON_PATH) as f:
        data = json.load(f)
    # Support both bare list and wrapped {"waterfalls": [...]}
    if isinstance(data, list):
        return data
    return data.get("waterfalls", [])


def save_waterfalls(waterfalls: list[dict]) -> None:
    waterfalls.sort(key=lambda w: w.get("name", ""))
    with open(JSON_PATH, "w") as f:
        json.dump(waterfalls, f, indent=2)
    print(f"\n✅  Saved {len(waterfalls)} waterfalls → {JSON_PATH}")


def save_source_counts(waterfalls: list[dict]) -> None:
    from collections import Counter
    county_counts = Counter(w.get("county", "Unknown") for w in waterfalls)
    state_counts  = Counter(w.get("state",  "Unknown") for w in waterfalls)
    data = {
        "generated":    datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "total":        len(waterfalls),
        "by_county":    dict(sorted(county_counts.items())),
        "by_state":     dict(sorted(state_counts.items())),
    }
    with open(COUNTS_PATH, "w") as f:
        json.dump(data, f, indent=2)
    print(f"📊  Source counts → {COUNTS_PATH}")


# ---------------------------------------------------------------------------
# Phase 1: OSM seed
# ---------------------------------------------------------------------------

def run_seed(waterfalls: list[dict], bbox: tuple) -> list[dict]:
    print("🗺  Phase 1: OSM seed")
    print(f"   Bounding box: {bbox}")
    osm_results = fetch_osm_waterfalls(bbox)
    print(f"   OSM returned {len(osm_results)} waterfall elements")
    merged = merge_osm_into_existing(osm_results, waterfalls)
    print(f"   Merged → {len(merged)} total waterfalls")
    return merged


# ---------------------------------------------------------------------------
# Phase 2: Live update
# ---------------------------------------------------------------------------

def run_update(
    waterfalls: list[dict],
    nps_key: str,
    skip_nps: bool,
    skip_precip: bool,
) -> list[dict]:
    print("\n💧  Phase 2: Live data update")

    # 2a. USGS flow + Open-Meteo precip per waterfall
    updated = []
    for i, wf in enumerate(waterfalls, 1):
        name = wf.get("name", "?")
        print(f"  [{i}/{len(waterfalls)}] {name}")
        # Pass skip_precip flag by temporarily nulling lat/lon if requested
        if skip_precip:
            tmp = dict(wf)
            tmp["lat"] = None
            tmp["lon"] = None
            result = update_waterfall(tmp)
            # Restore location
            result["lat"] = wf["lat"]
            result["lon"] = wf["lon"]
            updated.append(result)
        else:
            updated.append(update_waterfall(wf))

    # 2b. NPS closures
    if not skip_nps and nps_key:
        print("\n📡  Fetching NPS closure alerts...")
        # Collect unique nps_unit codes present in our data
        nps_units = list({
            w["nps_unit"].lower()
            for w in updated
            if w.get("nps_unit")
        })
        if nps_units:
            # fetch_nps_alerts accepts a list of park codes
            nps_alerts = _fetch_nps_alerts_for_units(nps_key, nps_units)
            updated = apply_nps_closures_to_waterfalls(updated, nps_alerts)
        else:
            print("   No NPS units configured — skipping")
    elif not nps_key:
        print("⚠️   No NPS API key — skipping NPS closure check (set NPS_API_KEY)")
    else:
        print("⏭️   Skipping NPS alerts")

    return updated


def _fetch_nps_alerts_for_units(api_key: str, units: list[str]) -> dict[str, list[dict]]:
    """Fetch NPS alerts for the specific nps_unit codes found in our waterfall data."""
    from nps import fetch_nps_alerts as _fetch

    # fetch_nps_alerts in nps.py uses PARK_CODES constant; we monkey-patch temporarily
    import nps as nps_module
    original = nps_module.PARK_CODES
    nps_module.PARK_CODES = units
    try:
        result = _fetch(api_key)
    finally:
        nps_module.PARK_CODES = original
    return result


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="High Country Outdoors — Waterfall Scraper")
    parser.add_argument("--seed",         action="store_true", help="Run OSM seed phase")
    parser.add_argument("--skip-update",  action="store_true", help="Skip live data update phase")
    parser.add_argument("--nps-key",      default=os.environ.get("NPS_API_KEY", ""), help="NPS API key")
    parser.add_argument("--skip-nps",     action="store_true", help="Skip NPS closure fetch")
    parser.add_argument("--skip-precip",  action="store_true", help="Skip Open-Meteo precipitation fetch")
    parser.add_argument("--bbox",         default=None, help="Override bounding box: 'south,west,north,east'")
    args = parser.parse_args()

    print("💧  High Country Outdoors — Waterfall Scraper")
    print(f"   Output: {JSON_PATH}")
    print()

    bbox = DEFAULT_BBOX
    if args.bbox:
        try:
            bbox = tuple(float(x) for x in args.bbox.split(","))
        except ValueError:
            print(f"❌  Invalid --bbox format: {args.bbox}")
            sys.exit(1)

    waterfalls = load_waterfalls()
    print(f"Loaded {len(waterfalls)} existing waterfalls\n")

    # Phase 1: Seed
    if args.seed:
        waterfalls = run_seed(waterfalls, bbox)

    # Phase 2: Live update (default unless --skip-update)
    if not args.skip_update:
        waterfalls = run_update(
            waterfalls,
            nps_key=args.nps_key,
            skip_nps=args.skip_nps,
            skip_precip=args.skip_precip,
        )

    # Save
    save_waterfalls(waterfalls)
    save_source_counts(waterfalls)


if __name__ == "__main__":
    main()
