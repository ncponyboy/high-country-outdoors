#!/usr/bin/env python3
"""
High Country Outdoors — Trail Conditions Scraper
=================================================
Runs daily via GitHub Actions.

Pipeline:
  1. Load existing trail_conditions.json (preserves manual data)
  2. Fetch NPS alerts for Blue Ridge Parkway + AT
  3. Fetch Open-Meteo weather at each trailhead
  4. Apply automated updates (respects `locked: true` on any trail)
  5. Write updated trail_conditions.json

Usage:
  python scraper.py --nps-key YOUR_KEY

  NPS API key (free): https://www.nps.gov/subjects/developer/get-started.htm
  Set as GitHub Secret: NPS_API_KEY
"""

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path

from nps import fetch_nps_alerts, apply_nps_alerts
from weather import apply_weather_to_trail

REPO_ROOT           = Path(__file__).resolve().parent.parent
JSON_PATH           = REPO_ROOT / "trail_conditions.json"
WATERFALLS_JSON     = REPO_ROOT / "waterfalls.json"


def load_trails() -> dict:
    with open(JSON_PATH, "r") as f:
        return json.load(f)


def save_trails(data: dict) -> None:
    data["last_updated"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    data["total_trails"] = len(data["trails"])
    with open(JSON_PATH, "w") as f:
        json.dump(data, f, indent=2)
    print(f"\n✅ Saved {data['total_trails']} trails → {JSON_PATH}")


def reset_weather_alerts(trails: list[dict]) -> list[dict]:
    """
    Clear auto-generated weather alerts before each run so they
    don't accumulate. Manually-locked trails are skipped.
    """
    for trail in trails:
        if not trail.get("locked"):
            # Remove any previous weather-generated alert texts
            trail["alerts"] = [
                a for a in trail.get("alerts", [])
                if not any(kw in (a.get("message", "") if isinstance(a, dict) else a).lower()
                           for kw in ["rain", "snow", "icy", "water crossing"])
            ]
    return trails


def main():
    parser = argparse.ArgumentParser(description="High Country Outdoors scraper")
    parser.add_argument("--nps-key",        default=os.environ.get("NPS_API_KEY", ""), help="NPS API key")
    parser.add_argument("--skip-weather",   action="store_true", help="Skip weather fetch (faster for testing)")
    parser.add_argument("--skip-nps",       action="store_true", help="Skip NPS alerts fetch")
    parser.add_argument("--waterfalls",     action="store_true", help="Also run waterfall live-data update")
    parser.add_argument("--waterfalls-seed", action="store_true", help="Run waterfall OSM seed phase too")
    args = parser.parse_args()

    print("🥾 High Country Outdoors — Trail Conditions Scraper")
    print(f"   JSON: {JSON_PATH}")
    print()

    # 1. Load
    data = load_trails()
    trails = data["trails"]
    print(f"Loaded {len(trails)} trails\n")

    # 2. Reset auto alerts (keeps manual ones via locked flag)
    trails = reset_weather_alerts(trails)

    # 3. NPS alerts
    nps_alerts = {}
    if not args.skip_nps and args.nps_key:
        print("📡 Fetching NPS alerts...")
        nps_alerts = fetch_nps_alerts(args.nps_key)
        trails = [apply_nps_alerts(t, nps_alerts) for t in trails]
    elif not args.nps_key:
        print("⚠️  No NPS API key — skipping NPS alerts (set NPS_API_KEY env var)")
    else:
        print("⏭️  Skipping NPS alerts")

    # 4. Weather
    if not args.skip_weather:
        print("\n🌤  Fetching trailhead weather...")
        updated_trails = []
        for trail in trails:
            print(f"  {trail['name']}...")
            updated_trails.append(apply_weather_to_trail(trail))
        trails = updated_trails
    else:
        print("⏭️  Skipping weather fetch")

    # 5. Save trails
    data["trails"] = trails
    save_trails(data)

    # 6. Waterfalls (optional — triggered by --waterfalls or --waterfalls-seed)
    if args.waterfalls or args.waterfalls_seed:
        print("\n💧  Running waterfall update...")
        try:
            import subprocess, sys
            wf_cmd = [sys.executable, str(Path(__file__).parent / "waterfall_scraper.py")]
            if args.waterfalls_seed:
                wf_cmd.append("--seed")
            if args.skip_nps:
                wf_cmd.append("--skip-nps")
            if args.nps_key:
                wf_cmd += ["--nps-key", args.nps_key]
            subprocess.run(wf_cmd, check=True)
        except Exception as e:
            print(f"  ⚠️  Waterfall scraper error: {e}")


if __name__ == "__main__":
    main()
