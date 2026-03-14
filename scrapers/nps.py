"""
NPS API — fetch active alerts for Blue Ridge Parkway and Appalachian Trail.
Maps NPS alert categories to trail status and alert text.
API key is free: https://www.nps.gov/subjects/developer/get-started.htm
"""

import requests
from typing import Optional

NPS_BASE = "https://developer.nps.gov/api/v1"

# Park codes relevant to our trail regions
PARK_CODES = ["blri", "appa"]

# NPS alert categories → our status
CATEGORY_MAP = {
    "Park Closure": "closed",
    "Trail Closure": "closed",
    "Road Closure": "closed",
    "Danger": "caution",
    "Caution": "caution",
    "Information": None,   # informational only — don't change status
}


def fetch_nps_alerts(api_key: str) -> dict[str, list[dict]]:
    """
    Returns a dict keyed by park code with list of active alerts.
    Example: { "blri": [{"title": "...", "description": "...", "status": "caution"}] }
    """
    all_alerts: dict[str, list[dict]] = {}

    for park_code in PARK_CODES:
        try:
            resp = requests.get(
                f"{NPS_BASE}/alerts",
                params={"parkCode": park_code, "limit": 50, "api_key": api_key},
                timeout=15,
            )
            resp.raise_for_status()
            data = resp.json()

            alerts = []
            for item in data.get("data", []):
                category = item.get("category", "")
                title = item.get("title", "").strip()
                description = item.get("description", "").strip()
                status = CATEGORY_MAP.get(category)

                alerts.append({
                    "title": title,
                    "description": description,
                    "category": category,
                    "status": status,        # None = don't override trail status
                    "url": item.get("url", ""),
                })

            all_alerts[park_code] = alerts
            print(f"  NPS {park_code.upper()}: {len(alerts)} alerts")

        except Exception as e:
            print(f"  NPS {park_code} error: {e}")
            all_alerts[park_code] = []

    return all_alerts


def park_code_for_trail(trail: dict) -> Optional[str]:
    """Map a trail's park name to an NPS park code."""
    park = trail.get("park", "").lower()
    if "blue ridge parkway" in park:
        return "blri"
    if "appalachian" in trail.get("name", "").lower():
        return "appa"
    return None


def apply_nps_alerts(trail: dict, nps_alerts: dict[str, list[dict]]) -> dict:
    """
    Apply NPS alerts to a single trail object.
    Returns updated trail dict.
    """
    park_code = park_code_for_trail(trail)
    if not park_code or park_code not in nps_alerts:
        return trail

    alerts = nps_alerts[park_code]
    if not alerts:
        return trail

    # Collect alert titles as our alert strings
    alert_texts = []
    worst_status = None

    status_rank = {"closed": 2, "caution": 1, None: 0}

    for alert in alerts:
        title = alert["title"]
        if title:
            alert_texts.append(title)
        s = alert["status"]
        if status_rank.get(s, 0) > status_rank.get(worst_status, 0):
            worst_status = s

    if alert_texts:
        trail["alerts"] = alert_texts[:3]   # cap at 3 alerts

    if worst_status and not trail.get("locked"):
        trail["conditions"]["status"] = worst_status

    return trail
