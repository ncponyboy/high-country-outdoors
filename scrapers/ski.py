#!/usr/bin/env python3
"""
High Country Outdoors — Ski Conditions Scraper
===============================================
Fetches OnTheSnow pages for NC and TN, parses the __NEXT_DATA__ JSON
embedded in the page, filters for our 4 target resorts, and writes
ski_conditions.json to the repo root.

Target resorts:
  - Sugar Mountain Resort         (NC)
  - Beech Mountain Resort         (NC)
  - Appalachian Ski Mountain      (NC)
  - Ober Mountain                 (TN)

Usage:
  python ski.py [--dry-run]

  --dry-run   Parse and print JSON without writing to disk
"""

import json
import re
import sys
import argparse
from datetime import datetime, timezone
from pathlib import Path

try:
    import requests
except ImportError:
    print("ERROR: 'requests' not installed. Run: pip install requests")
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_PATH = REPO_ROOT / "ski_conditions.json"

# Pages to scrape
SOURCES = [
    {
        "state": "NC",
        "url": "https://www.onthesnow.com/north-carolina/skireport",
    },
    {
        "state": "TN",
        "url": "https://www.onthesnow.com/tennessee/skireport",
    },
]

# Canonical resort definitions — used to match scraped data and fill in
# static fields (coordinates, website, onthesnow URL) that OnTheSnow
# doesn't always expose cleanly.
RESORT_REGISTRY = {
    "sugar mountain resort": {
        "id": "sugar-mountain-resort",
        "name": "Sugar Mountain Resort",
        "region": "High Country NC",
        "latitude": 36.1156,
        "longitude": -81.8687,
        "website_url": "https://www.sugarmtn.com",
        "onthesnow_url": "https://www.onthesnow.com/north-carolina/sugar-mountain-resort/skireport",
    },
    "beech mountain resort": {
        "id": "beech-mountain-resort",
        "name": "Beech Mountain Resort",
        "region": "High Country NC",
        "latitude": 36.1901,
        "longitude": -81.8782,
        "website_url": "https://www.skibeechmountain.com",
        "onthesnow_url": "https://www.onthesnow.com/north-carolina/beech-mountain-resort/skireport",
    },
    "appalachian ski mountain": {
        "id": "appalachian-ski-mountain",
        "name": "Appalachian Ski Mountain",
        "region": "High Country NC",
        "latitude": 36.1353,
        "longitude": -81.6832,
        "website_url": "https://www.appskimtn.com",
        "onthesnow_url": "https://www.onthesnow.com/north-carolina/appalachian-ski-mountain/skireport",
    },
    "ober mountain": {
        "id": "ober-mountain",
        "name": "Ober Mountain",
        "region": "Great Smoky Mountains TN",
        "latitude": 35.7143,
        "longitude": -83.5102,
        "website_url": "https://www.obergatlinburg.com",
        "onthesnow_url": "https://www.onthesnow.com/tennessee/ober-mountain/skireport",
    },
}

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/122.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}


# ---------------------------------------------------------------------------
# Fetching + parsing
# ---------------------------------------------------------------------------

def fetch_page(url: str) -> str:
    """Fetch a page, returning raw HTML text."""
    print(f"  GET {url}")
    resp = requests.get(url, headers=HEADERS, timeout=30)
    resp.raise_for_status()
    return resp.text


def extract_next_data(html: str) -> dict:
    """
    Pull the JSON object from <script id="__NEXT_DATA__">...</script>.
    Returns an empty dict if not found.
    """
    match = re.search(
        r'<script[^>]+id=["\']__NEXT_DATA__["\'][^>]*>(.*?)</script>',
        html,
        re.DOTALL,
    )
    if not match:
        print("  WARNING: __NEXT_DATA__ script tag not found")
        return {}
    return json.loads(match.group(1))


def safe_int(value) -> int | None:
    """Convert a value to int, returning None on failure."""
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def safe_float(value) -> float | None:
    """Convert a value to float, returning None on failure."""
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def normalize_name(name: str) -> str:
    """Lowercase + strip for dict key matching."""
    return name.strip().lower()


# ---------------------------------------------------------------------------
# Resort data extraction
# OnTheSnow embeds resort objects under several possible paths inside
# __NEXT_DATA__.  We walk the common candidates and return the first hit.
# ---------------------------------------------------------------------------

def find_resort_list(page_props: dict) -> list[dict]:
    """
    Return a list of resort dicts from pageProps.
    OnTheSnow has used (at minimum) these paths over time:
      pageProps.resorts
      pageProps.skiReport.resorts
      pageProps.data.resorts
      pageProps.initialData.resorts
    We try them all and fall back to an empty list.
    """
    candidates = [
        page_props.get("resorts"),
        page_props.get("skiReport", {}).get("resorts"),
        page_props.get("data", {}).get("resorts"),
        page_props.get("initialData", {}).get("resorts"),
    ]
    for c in candidates:
        if isinstance(c, list) and c:
            return c
    # Last resort: walk the top level for any list of dicts that look like resorts
    for key, val in page_props.items():
        if isinstance(val, list) and val and isinstance(val[0], dict):
            if any(k in val[0] for k in ("name", "slug", "openTrails", "baseDepth")):
                return val
        if isinstance(val, dict):
            for subkey, subval in val.items():
                if isinstance(subval, list) and subval and isinstance(subval[0], dict):
                    if any(k in subval[0] for k in ("name", "slug", "openTrails", "baseDepth")):
                        return subval
    return []


def parse_resort(raw: dict, registry_entry: dict) -> dict:
    """
    Build a normalized resort dict from a raw OnTheSnow resort object.
    OnTheSnow field names have changed over time; we try multiple aliases.
    """
    now_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # --- Status ---
    # Possible field names: isOpen, status, openStatus, open
    is_open = (
        raw.get("isOpen")
        or raw.get("open")
        or str(raw.get("status", "")).lower() in ("open", "1", "true")
        or str(raw.get("openStatus", "")).lower() == "open"
    )
    # Only trust "open" if at least one trail/lift is reported open
    open_trails_raw = (
        safe_int(raw.get("openTrails"))
        or safe_int(raw.get("openRuns"))
        or safe_int(raw.get("runs", {}).get("open") if isinstance(raw.get("runs"), dict) else None)
    )
    if open_trails_raw is None:
        open_trails_raw = 0

    total_trails_raw = (
        safe_int(raw.get("totalTrails"))
        or safe_int(raw.get("totalRuns"))
        or safe_int(raw.get("runs", {}).get("total") if isinstance(raw.get("runs"), dict) else None)
        or 0
    )
    open_lifts_raw = (
        safe_int(raw.get("openLifts"))
        or safe_int(raw.get("lifts", {}).get("open") if isinstance(raw.get("lifts"), dict) else None)
        or 0
    )
    total_lifts_raw = (
        safe_int(raw.get("totalLifts"))
        or safe_int(raw.get("lifts", {}).get("total") if isinstance(raw.get("lifts"), dict) else None)
        or 0
    )

    # Override status: if no trails/lifts open it's effectively closed
    if open_trails_raw == 0 and open_lifts_raw == 0:
        is_open = False
    status = "open" if is_open else "closed"

    # --- Snow depth ---
    # Possible: baseDepthLow/High, baseDepth (single), snowBase, snowpack
    base_low = (
        safe_int(raw.get("baseDepthLow"))
        or safe_int(raw.get("snowBaseLow"))
        or safe_int(raw.get("baseDepth"))
        or safe_int(raw.get("snowBase"))
        or safe_int(raw.get("snowpack"))
    )
    base_high = (
        safe_int(raw.get("baseDepthHigh"))
        or safe_int(raw.get("snowBaseHigh"))
        or base_low  # fall back to low if only one value available
    )

    # --- New snow ---
    new_snow = (
        safe_float(raw.get("newSnow72h"))
        or safe_float(raw.get("newSnow48h"))
        or safe_float(raw.get("newSnow24h"))
        or safe_float(raw.get("snowfall72h"))
        or safe_float(raw.get("snowfall48h"))
        or 0.0
    )

    # --- Surface ---
    surface = (
        raw.get("surface")
        or raw.get("surfaceConditions")
        or raw.get("primarySurface")
        or raw.get("conditions")
        or raw.get("snowConditions")
    )
    if isinstance(surface, dict):
        # Sometimes it's {"primary": "...", "secondary": "..."}
        surface = surface.get("primary") or surface.get("text")
    if surface:
        surface = str(surface).strip()

    # --- Last updated ---
    last_updated_raw = (
        raw.get("lastUpdated")
        or raw.get("updatedAt")
        or raw.get("reportDate")
        or now_iso
    )
    # Ensure it's a string
    last_updated_str = str(last_updated_raw) if last_updated_raw else now_iso

    return {
        **registry_entry,
        "status": status,
        "base_depth_low": base_low,
        "base_depth_high": base_high,
        "new_snow_72h": new_snow,
        "open_trails": open_trails_raw,
        "total_trails": total_trails_raw,
        "open_lifts": open_lifts_raw,
        "total_lifts": total_lifts_raw,
        "surface": surface,
        "last_updated": last_updated_str,
    }


def closed_resort(registry_entry: dict) -> dict:
    """Return a closed placeholder for a resort that wasn't found in scraped data."""
    now_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        **registry_entry,
        "status": "closed",
        "base_depth_low": None,
        "base_depth_high": None,
        "new_snow_72h": 0.0,
        "open_trails": 0,
        "total_trails": 0,
        "open_lifts": 0,
        "total_lifts": 0,
        "surface": None,
        "last_updated": now_iso,
    }


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def scrape_all() -> list[dict]:
    """
    Scrape NC and TN OnTheSnow pages and return a list of resort dicts
    for our 4 target resorts.
    """
    found: dict[str, dict] = {}  # key = registry key, value = resort dict

    for source in SOURCES:
        print(f"\n📡 Scraping {source['state']} page...")
        try:
            html = fetch_page(source["url"])
        except Exception as e:
            print(f"  ERROR fetching {source['url']}: {e}")
            continue

        next_data = extract_next_data(html)
        if not next_data:
            continue

        # Navigate to pageProps
        page_props = next_data.get("props", {}).get("pageProps", {})
        if not page_props:
            # Some versions put everything at the top level
            page_props = next_data

        resort_list = find_resort_list(page_props)
        print(f"  Found {len(resort_list)} resorts on page")

        for raw_resort in resort_list:
            raw_name = raw_resort.get("name") or raw_resort.get("title") or ""
            norm = normalize_name(raw_name)

            # Find matching registry entry (substring match for robustness)
            matched_key = None
            for key in RESORT_REGISTRY:
                if key in norm or norm in key:
                    matched_key = key
                    break

            if matched_key and matched_key not in found:
                print(f"  ✓ Matched: {raw_name}")
                found[matched_key] = parse_resort(raw_resort, RESORT_REGISTRY[matched_key])

    # Fill in any resorts not found on the pages with closed placeholders
    results = []
    for key, registry_entry in RESORT_REGISTRY.items():
        if key in found:
            results.append(found[key])
        else:
            print(f"  ⚠ Not found in scraped data, marking closed: {registry_entry['name']}")
            results.append(closed_resort(registry_entry))

    return results


def main():
    parser = argparse.ArgumentParser(description="High Country Outdoors — Ski Conditions Scraper")
    parser.add_argument("--dry-run", action="store_true", help="Print output without writing to disk")
    args = parser.parse_args()

    print("🎿 High Country Outdoors — Ski Conditions Scraper")
    print(f"   Output: {OUTPUT_PATH}")

    resorts = scrape_all()

    output = {
        "last_updated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "resorts": resorts,
    }

    if args.dry_run:
        print("\n--- DRY RUN OUTPUT ---")
        print(json.dumps(output, indent=2))
    else:
        with open(OUTPUT_PATH, "w") as f:
            json.dump(output, f, indent=2)
        print(f"\n✅ Wrote {len(resorts)} resorts → {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
