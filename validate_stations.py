#!/usr/bin/env python3
"""VTA Station Validation Script - Station data from Station.swift"""

import requests, time, json, argparse
from datetime import datetime, timezone

API_KEY = "cfc3474b-61e1-48f4-a177-0c8b8cb27cca"
BASE_URL = "https://api.511.org/transit/StopMonitoring"

LINES = {
    "orange": {"name": "Orange Line", "color": "🟠", "line_ref": "Orange Line", "directions": {"E": "→ Alum Rock", "W": "→ Mountain View"}},
    "blue": {"name": "Blue Line", "color": "🔵", "line_ref": "Blue Line", "directions": {"N": "→ Baypointe", "S": "→ Santa Teresa"}},
    "green": {"name": "Green Line", "color": "🟢", "line_ref": "Green Line", "directions": {"N": "→ Old Ironsides", "S": "→ Winchester"}}
}

# Orange Line: (eastbound_id, westbound_id, name)
ORANGE = [
    ("64786", "64821", "Mountain View"), ("64788", "64819", "Whisman"), ("64789", "64818", "Middlefield"),
    ("64790", "64817", "Bayshore/NASA"), ("65024", "65025", "Moffett Park"), ("64791", "64816", "Lockheed Martin"),
    ("64792", "64815", "Borregas"), ("64793", "64814", "Crossman"), ("64794", "64813", "Fair Oaks"),
    ("64795", "64812", "Vienna"), ("64796", "64811", "Reamwood"), ("64797", "64810", "Old Ironsides"),
    ("64798", "64809", "Great America"), ("64799", "64808", "Lick Mill"), ("64800", "64807", "Champion"),
    ("64801", "64806", "Baypointe"), ("64802", "64805", "Cisco Way"), ("64803", "64804", "Alder"),
    ("65235", "65250", "Great Mall"), ("65236", "65249", "Milpitas"), ("65237", "65248", "Cropley"),
    ("65238", "65247", "Hostetter"), ("65239", "65246", "Berryessa"), ("65240", "65245", "Penitencia Creek"),
    ("65241", "65244", "McKee"), ("65242", "65243", "Alum Rock"),
]

# Blue Line: (northbound_id, southbound_id, name)
BLUE = [
    ("64801", "64761", "Baypointe"), ("64759", "64762", "Tasman"), ("64758", "64763", "River Oaks"),
    ("64757", "64764", "Orchard"), ("64756", "64765", "Bonaventura"), ("64755", "64766", "Component"),
    ("64754", "64767", "Karina"), ("64753", "64768", "Metro/Airport"), ("64752", "64769", "Gish"),
    ("64751", "64770", "Civic Center"), ("64750", "64771", "Japantown/Ayer"), ("64749", "64772", "St. James"),
    ("64748", "64773", "Santa Clara"), ("64747", "64774", "San Antonio"), ("64746", "64775", "Convention Center"),
    ("64745", "64776", "Children's Discovery Museum"), ("64744", "64777", "Virginia"), ("64743", "64778", "Tamien"),
    ("64742", "64779", "Curtner"), ("64741", "64780", "Capitol"), ("64740", "64781", "Branham"),
    ("64731", "64733", "Ohlone/Chynoweth"), ("64739", "64782", "Blossom Hill"), ("64738", "64783", "Snell"),
    ("64737", "64784", "Cottle"), ("64736", "64785", "Santa Teresa"),
]

# Green Line: (northbound_id, southbound_id, name)
GREEN = [
    ("64810", "64797", "Old Ironsides"), ("64809", "64798", "Great America"), ("64808", "64799", "Lick Mill"),
    ("64807", "64800", "Champion"), ("64759", "64762", "Tasman"), ("64758", "64763", "River Oaks"),
    ("64757", "64764", "Orchard"), ("64756", "64765", "Bonaventura"), ("64755", "64766", "Component"),
    ("64754", "64767", "Karina"), ("64753", "64768", "Metro/Airport"), ("64752", "64769", "Gish"),
    ("64751", "64770", "Civic Center"), ("64750", "64771", "Japantown/Ayer"), ("64749", "64772", "St. James"),
    ("64748", "64773", "Santa Clara"), ("64747", "64774", "San Antonio"), ("64746", "64775", "Convention Center"),
    ("65388", "65389", "San Fernando"), ("65374", "65381", "San Jose Diridon"), ("65375", "65382", "Race"),
    ("65376", "65383", "Fruitdale"), ("65377", "65384", "Bascom"), ("65378", "65385", "Hamilton"),
    ("65379", "65386", "Campbell"), ("65380", "65387", "Winchester"),
]

def now_str():
    return datetime.now().strftime("%H:%M:%S")

def fetch(stop_code, line_ref=None):
    url = f"{BASE_URL}?api_key={API_KEY}&agency=SC&stopCode={stop_code}&format=json"
    try:
        r = requests.get(url, timeout=15)
        text = r.text.lstrip('\ufeff')
        if "exceeded" in text.lower(): return None, "RATE_LIMITED"
        data = json.loads(text)
        visits = data.get("ServiceDelivery", {}).get("StopMonitoringDelivery", {}).get("MonitoredStopVisit", []) or []
        preds = []
        for v in visits:
            j = v.get("MonitoredVehicleJourney", {})
            if line_ref and j.get("LineRef") != line_ref: continue
            call = j.get("MonitoredCall", {})
            exp = call.get("ExpectedArrivalTime", "")
            mins = None
            arr_time = ""
            if exp:
                try:
                    arr = datetime.fromisoformat(exp.replace('Z', '+00:00'))
                    now = datetime.now(arr.tzinfo)
                    mins = max(0, int((arr - now).total_seconds() / 60))
                    arr_local = arr.astimezone()
                    arr_time = arr_local.strftime("%H:%M")
                except: pass
            preds.append({"mins": mins, "dest": j.get("DestinationName", "?"), "dir": j.get("DirectionRef", ""), "time": arr_time})
        preds.sort(key=lambda x: x["mins"] if x["mins"] is not None else 999)
        return preds, "OK"
    except Exception as e: return [], str(e)

def fmt(preds):
    if not preds: return "No trains"
    parts = []
    has_time = False
    for p in preds[:3]:
        if p['mins'] is not None:
            has_time = True
            parts.append(f"{p['mins']}min@{p['time']}→{p['dest']}")
        else:
            parts.append(f"(departure)→{p['dest']}")
    # If all predictions have no time, it's likely a terminus station
    if not has_time and preds:
        return f"🚉 Terminus (trains depart here) → {preds[0]['dest']}"
    return " | ".join(parts)

def sample_stations(stations, n=5):
    if len(stations) <= n: return stations
    indices = [0]
    step = (len(stations) - 1) / (n - 1)
    for i in range(1, n - 1): indices.append(int(i * step))
    indices.append(len(stations) - 1)
    return [stations[i] for i in sorted(set(indices))]

def validate(line_key, stations, quick=False, sample=0):
    cfg = LINES[line_key]
    if quick: stations = [stations[len(stations)//2]]
    elif sample > 0: stations = sample_stations(stations, sample)
    print(f"\n{'='*80}\n{cfg['color']} {cfg['name']} - testing {len(stations)} stations [{now_str()}]\n{'='*80}")
    res = {"ok": 0, "no": 0, "err": 0}
    d1, d2 = ("E", "W") if line_key == "orange" else ("N", "S")
    for s1, s2, name in stations:
        print(f"\n📍 {name} ({d1}={s1}, {d2}={s2}) [{now_str()}]")
        for stop, d in [(s1, d1), (s2, d2)]:
            preds, st = fetch(stop, cfg["line_ref"])
            if st == "RATE_LIMITED": print("⚠️ Rate limited!"); return res
            if st == "OK" and preds: res["ok"] += 1; print(f"   {cfg['directions'][d]}: ✅ {fmt(preds)}")
            elif st == "OK": res["no"] += 1; print(f"   {cfg['directions'][d]}: ⚠️ No trains")
            else: res["err"] += 1; print(f"   {cfg['directions'][d]}: ❌ {st}")
            time.sleep(0.3)
    return res

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--quick", action="store_true", help="Test 1 station per line")
    p.add_argument("--sample", type=int, default=5, help="Sample N stations per line (default: 5)")
    p.add_argument("--all", action="store_true", help="Test all stations")
    p.add_argument("--line", choices=["orange", "blue", "green"])
    args = p.parse_args()
    print(f"{'='*80}\nVTA VALIDATION - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n{'='*80}")
    total = {"ok": 0, "no": 0, "err": 0}
    lines = [(args.line, {"orange": ORANGE, "blue": BLUE, "green": GREEN}[args.line])] if args.line else [("orange", ORANGE), ("blue", BLUE), ("green", GREEN)]
    sample = 0 if args.all else (1 if args.quick else args.sample)
    for k, s in lines:
        r = validate(k, s, quick=args.quick, sample=sample if not args.quick else 0)
        for x in r: total[x] += r[x]
    print(f"\n{'='*80}\nSUMMARY: ✅{total['ok']} | ⚠️{total['no']} | ❌{total['err']} [{now_str()}]\n{'='*80}")

if __name__ == "__main__": main()
