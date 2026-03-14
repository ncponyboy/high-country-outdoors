"""
Open-Meteo — fetch current weather conditions at each trailhead.
Free, no API key required.
Used to automatically flag caution when:
  - Recent heavy rain (raises water crossing risk)
  - Recent snow at elevation
  - High winds on exposed summits
"""

import uuid
import requests
from datetime import datetime, timezone
from typing import Optional

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

# mm of precipitation in last 24h that triggers a caution flag
RAIN_CAUTION_THRESHOLD_MM = 25.0   # ~1 inch
SNOW_CAUTION_THRESHOLD_MM = 50.0   # ~2 inches snow water equivalent


def fetch_weather_for_trail(lat: float, lon: float) -> Optional[dict]:
    """
    Returns a simple weather summary dict for a trailhead location.
    Uses hourly data for the past 24h + next 24h.
    """
    try:
        resp = requests.get(
            OPEN_METEO_URL,
            params={
                "latitude": lat,
                "longitude": lon,
                "daily": "precipitation_sum,snowfall_sum,windspeed_10m_max,weathercode",
                "hourly": "temperature_2m,precipitation",
                "current_weather": True,
                "temperature_unit": "fahrenheit",
                "windspeed_unit": "mph",
                "precipitation_unit": "mm",
                "timezone": "America/New_York",
                "past_days": 1,
                "forecast_days": 2,
            },
            timeout=15,
        )
        resp.raise_for_status()
        return resp.json()

    except Exception as e:
        print(f"    Weather error at ({lat},{lon}): {e}")
        return None


def weather_summary(data: dict) -> dict:
    """
    Extract a concise summary from Open-Meteo response.
    Returns: { rain_24h_mm, snow_24h_mm, temp_f, wind_mph, condition_flag }
    condition_flag: "clear" | "caution" | "closed"
    """
    summary = {
        "rain_24h_mm": 0.0,
        "snow_24h_mm": 0.0,
        "temp_f": None,
        "wind_mph": None,
        "condition_flag": "clear",
        "alert_text": None,
    }

    try:
        current = data.get("current_weather", {})
        summary["temp_f"] = current.get("temperature")
        summary["wind_mph"] = current.get("windspeed")

        daily = data.get("daily", {})
        precip_list = daily.get("precipitation_sum", [])
        snow_list = daily.get("snowfall_sum", [])

        # Index 0 = yesterday, index 1 = today
        if len(precip_list) >= 2:
            summary["rain_24h_mm"] = (precip_list[0] or 0) + (precip_list[1] or 0)
        if len(snow_list) >= 2:
            summary["snow_24h_mm"] = (snow_list[0] or 0) + (snow_list[1] or 0)

        alerts = []
        if summary["snow_24h_mm"] >= SNOW_CAUTION_THRESHOLD_MM:
            summary["condition_flag"] = "caution"
            inches = summary["snow_24h_mm"] / 25.4
            alerts.append(f"Recent snowfall ({inches:.1f}\") — expect icy conditions at elevation")
        elif summary["rain_24h_mm"] >= RAIN_CAUTION_THRESHOLD_MM:
            summary["condition_flag"] = "caution"
            inches = summary["rain_24h_mm"] / 25.4
            alerts.append(f"Recent heavy rain ({inches:.1f}\") — water crossings may be elevated")

        if alerts:
            summary["alert_text"] = alerts[0]

    except Exception as e:
        print(f"    Weather summary error: {e}")

    return summary


def apply_weather_to_trail(trail: dict) -> dict:
    """
    Fetch weather and apply conditions to a trail.
    Skips if trail is locked (manually curated).
    """
    if trail.get("locked"):
        return trail

    lat = trail.get("latitude")
    lon = trail.get("longitude")
    if not lat or not lon:
        return trail

    data = fetch_weather_for_trail(lat, lon)
    if not data:
        return trail

    summary = weather_summary(data)

    # Only upgrade status to caution (never downgrade from closed → open automatically)
    current_status = trail["conditions"].get("status", "open")
    status_rank = {"closed": 2, "caution": 1, "open": 0, "unknown": 0}

    if status_rank.get(summary["condition_flag"], 0) > status_rank.get(current_status, 0):
        trail["conditions"]["status"] = summary["condition_flag"]

    # Append weather alert as a proper TrailAlert object if not already present
    if summary["alert_text"]:
        existing = trail.get("alerts", [])
        existing_messages = [a.get("message", "") if isinstance(a, dict) else a for a in existing]
        if summary["alert_text"] not in existing_messages:
            alert_type = "flood" if "water crossing" in summary["alert_text"].lower() else "other"
            trail["alerts"] = existing + [{
                "id": str(uuid.uuid4()),
                "type": alert_type,
                "message": summary["alert_text"],
                "posted": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            }]

    return trail
