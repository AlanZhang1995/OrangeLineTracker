#!/usr/bin/env python3
"""
VTA Station API Checker
Checks if each station stop code returns valid data from 511.org API
With rate limiting to avoid API throttling
"""

import requests
import time
import json
from collections import defaultdict

API_KEY = "cfc3474b-61e1-48f4-a177-0c8b8cb27cca"
BASE_URL = "https://api.511.org/transit/StopMonitoring"

# All unique stop codes to check (deduplicated)
STATIONS = {
    # Orange Line
    "64786": ("Mountain View", "Orange", "E"),
    "64821": ("Mountain View", "Orange", "W"),
    "64788": ("Whisman", "Orange", "E"),
    "64819": ("Whisman", "Orange", "W"),
    "64789": ("Middlefield", "Orange", "E"),
    "64818": ("Middlefield", "Orange", "W"),
    "64790": ("Bayshore/NASA", "Orange", "E"),
    "64817": ("Bayshore/NASA", "Orange", "W"),
    "65024": ("Moffett Park", "Orange", "E"),
    "65025": ("Moffett Park", "Orange", "W"),
    "64791": ("Lockheed Martin", "Orange", "E"),
    "64816": ("Lockheed Martin", "Orange", "W"),
    "64792": ("Borregas", "Orange", "E"),
    "64815": ("Borregas", "Orange", "W"),
    "64793": ("Crossman", "Orange", "E"),
    "64814": ("Crossman", "Orange", "W"),
    "64794": ("Fair Oaks", "Orange", "E"),
    "64813": ("Fair Oaks", "Orange", "W"),
    "64795": ("Vienna", "Orange", "E"),
    "64812": ("Vienna", "Orange", "W"),
    "64796": ("Reamwood", "Orange", "E"),
    "64811": ("Reamwood", "Orange", "W"),
    "64797": ("Old Ironsides", "Orange", "E"),
    "64810": ("Old Ironsides", "Orange", "W"),
    "64798": ("Great America", "Orange", "E"),
    "64809": ("Great America", "Orange", "W"),
    "64799": ("Lick Mill", "Orange", "E"),
    "64808": ("Lick Mill", "Orange", "W"),
    "64800": ("Champion", "Orange", "E"),
    "64807": ("Champion", "Orange", "W"),
    "64801": ("Baypointe", "Orange", "E"),
    "64806": ("Baypointe", "Orange", "W"),
    "64802": ("Cisco Way", "Orange", "E"),
    "64805": ("Cisco Way", "Orange", "W"),
    "64803": ("Alder", "Orange", "E"),
    "64804": ("Alder", "Orange", "W"),
    "65235": ("Great Mall", "Orange", "E"),
    "65250": ("Great Mall", "Orange", "W"),
    "65236": ("Milpitas", "Orange", "E"),
    "65249": ("Milpitas", "Orange", "W"),
    "65237": ("Cropley", "Orange", "E"),
    "65248": ("Cropley", "Orange", "W"),
    "65238": ("Hostetter", "Orange", "E"),
    "65247": ("Hostetter", "Orange", "W"),
    "65239": ("Berryessa", "Orange", "E"),
    "65246": ("Berryessa", "Orange", "W"),
    "65240": ("Penitencia Creek", "Orange", "E"),
    "65245": ("Penitencia Creek", "Orange", "W"),
    "65241": ("McKee", "Orange", "E"),
    "65244": ("McKee", "Orange", "W"),
    "65242": ("Alum Rock", "Orange", "E"),
    "65243": ("Alum Rock", "Orange", "W"),
    
    # Blue Line specific (not shared with Orange)
    "64758": ("River Oaks", "Blue", "N"),
    "64759": ("River Oaks", "Blue", "S"),
    "64762": ("Tasman", "Blue/Green", "N"),
    "64763": ("Tasman", "Blue/Green", "S"),
    "64764": ("Orchard", "Blue", "N"),
    "64765": ("Orchard", "Blue", "S"),
    "64766": ("Karina", "Blue/Green", "N"),
    "64767": ("Karina", "Blue/Green", "S"),
    "64768": ("Component", "Blue/Green", "N"),
    "64769": ("Component", "Blue/Green", "S"),
    "64770": ("Bonaventura", "Blue/Green", "N"),
    "64771": ("Bonaventura", "Blue/Green", "S"),
    "64772": ("Metro/Airport", "Blue/Green", "N"),
    "64773": ("Metro/Airport", "Blue/Green", "S"),
    "64774": ("Gish", "Blue/Green", "N"),
    "64775": ("Gish", "Blue/Green", "S"),
    "64776": ("Civic Center", "Blue/Green", "N"),
    "64777": ("Civic Center", "Blue/Green", "S"),
    "64778": ("Japantown/Ayer", "Blue/Green", "N"),
    "64779": ("Japantown/Ayer", "Blue/Green", "S"),
    "64780": ("St. James", "Blue/Green", "N"),
    "64781": ("St. James", "Blue/Green", "S"),
    "64782": ("Santa Clara", "Blue/Green", "N"),
    "64783": ("Santa Clara", "Blue/Green", "S"),
    "64784": ("Paseo de San Antonio", "Blue/Green", "N"),
    "64785": ("Paseo de San Antonio", "Blue/Green", "S"),
    "64824": ("Convention Center", "Blue/Green", "N"),
    "64825": ("Convention Center", "Blue/Green", "S"),
    "64826": ("San Fernando/Diridon", "Blue/Green", "N"),
    "64827": ("San Fernando/Diridon", "Blue/Green", "S"),
    "64828": ("Virginia/San Fernando", "Blue/Green", "N"),
    "64829": ("Virginia/San Fernando", "Blue/Green", "S"),
    "64830": ("Tamien", "Blue", "N"),
    "64831": ("Tamien", "Blue", "S"),
    "64832": ("Curtner", "Blue", "N"),
    "64833": ("Curtner", "Blue", "S"),
    "64834": ("Capitol", "Blue", "N"),
    "64835": ("Capitol", "Blue", "S"),
    "64836": ("Branham", "Blue", "N"),
    "64837": ("Branham", "Blue", "S"),
    "64838": ("Ohlone/Chynoweth", "Blue", "N"),
    "64839": ("Ohlone/Chynoweth", "Blue", "S"),
    "64840": ("Blossom Hill", "Blue", "N"),
    "64841": ("Blossom Hill", "Blue", "S"),
    "64842": ("Snell", "Blue", "N"),
    "64843": ("Snell", "Blue", "S"),
    "64844": ("Cottle", "Blue", "N"),
    "64845": ("Cottle", "Blue", "S"),
    "64846": ("Santa Teresa", "Blue", "N"),
    "64847": ("Santa Teresa", "Blue", "S"),
    
    # Green Line specific
    "64848": ("Children's Discovery Museum", "Green", "N"),
    "64849": ("Children's Discovery Museum", "Green", "S"),
    "64850": ("Race", "Green", "N"),
    "64851": ("Race", "Green", "S"),
    "64852": ("Fruitdale", "Green", "N"),
    "64853": ("Fruitdale", "Green", "S"),
    "64854": ("Bascom", "Green", "N"),
    "64855": ("Bascom", "Green", "S"),
    "64856": ("Hamilton", "Green", "N"),
    "64857": ("Hamilton", "Green", "S"),
    "64858": ("Downtown Campbell", "Green", "N"),
    "64859": ("Downtown Campbell", "Green", "S"),
    "64860": ("Winchester", "Green", "N"),
    "64861": ("Winchester", "Green", "S"),
}

def check_stop(stop_code, station_name, line, direction):
    """Check if a stop code returns valid API data"""
    url = f"{BASE_URL}?api_key={API_KEY}&agency=SC&stopCode={stop_code}&format=json"
    
    try:
        response = requests.get(url, timeout=10)
        text = response.text
        
        # Remove BOM if present
        if text.startswith('\ufeff'):
            text = text[1:]
        
        if "exceeded" in text.lower():
            return "RATE_LIMITED", text
        
        data = json.loads(text)
        
        if "ServiceDelivery" in data:
            delivery = data["ServiceDelivery"].get("StopMonitoringDelivery", {})
            visits = delivery.get("MonitoredStopVisit", [])
            
            if visits is None:
                return "NO_DATA", "MonitoredStopVisit is null"
            elif len(visits) == 0:
                return "EMPTY", "No trains currently"
            else:
                # Check what lines are returned
                lines_found = set()
                for visit in visits:
                    line_ref = visit.get("MonitoredVehicleJourney", {}).get("LineRef", "")
                    lines_found.add(line_ref)
                return "OK", f"{len(visits)} trains, lines: {lines_found}"
        else:
            return "INVALID", "No ServiceDelivery in response"
            
    except json.JSONDecodeError as e:
        return "JSON_ERROR", str(e)
    except requests.RequestException as e:
        return "NETWORK_ERROR", str(e)
    except Exception as e:
        return "ERROR", str(e)

def main():
    print("VTA Station API Checker")
    print("=" * 60)
    print(f"Total unique stop codes to check: {len(STATIONS)}")
    print("Note: Rate limit is 60 requests per hour")
    print("=" * 60)
    print()
    
    results = defaultdict(list)
    checked = 0
    
    for stop_code, (name, line, direction) in sorted(STATIONS.items()):
        status, message = check_stop(stop_code, name, line, direction)
        
        if status == "RATE_LIMITED":
            print(f"\n⚠️  Rate limited! Checked {checked} stations.")
            print("Wait an hour and run again to check remaining stations.")
            break
        
        icon = {
            "OK": "✅",
            "EMPTY": "⚠️ ",
            "NO_DATA": "❓",
            "INVALID": "❌",
            "JSON_ERROR": "❌",
            "NETWORK_ERROR": "🔌",
            "ERROR": "❌"
        }.get(status, "❓")
        
        print(f"{icon} {stop_code} | {line:12} | {name:30} ({direction}) | {status}: {message[:50]}")
        
        results[status].append((stop_code, name, line, direction, message))
        checked += 1
        
        # Rate limiting: wait 1 second between requests
        time.sleep(1)
    
    print()
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    for status, items in sorted(results.items()):
        print(f"{status}: {len(items)} stations")
    
    # Print problematic stations
    if results.get("INVALID") or results.get("NO_DATA") or results.get("ERROR"):
        print()
        print("PROBLEMATIC STATIONS:")
        for status in ["INVALID", "NO_DATA", "ERROR", "JSON_ERROR"]:
            for stop_code, name, line, direction, message in results.get(status, []):
                print(f"  {stop_code}: {name} ({line} {direction}) - {message}")

if __name__ == "__main__":
    main()
