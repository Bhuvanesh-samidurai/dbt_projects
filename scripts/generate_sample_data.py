"""Generate the synthetic Bronze sample data used by the local (DuckDB) target.

The files mimic the shape of the London smart-meter dataset that is loaded
into Snowflake BRONZE in production:

  * dim_households.csv        one row per household (tariff + ACORN area group)
  * fact_energy_readings.csv  half-hourly kWh readings per meter
  * agg_daily_consumption.csv daily totals derived from the readings

A few deliberately bad rows (negative reading, missing meter id, missing daily
total) are included so the staging models' cleaning rules have something to do.

Run from the project root:  python scripts/generate_sample_data.py
"""

import csv
import math
import random
from datetime import datetime, timedelta
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent.parent / "seeds" / "sample_bronze"
START = datetime(2013, 1, 1)
DAYS = 3
SLOTS_PER_DAY = 48  # half-hourly readings

HOUSEHOLDS = [
    # LCLID,      tariff, ACORN,     ACORN group
    ("MAC000101", "Std", "ACORN-A", "Affluent"),
    ("MAC000102", "ToU", "ACORN-C", "Affluent"),
    ("MAC000103", "Std", "ACORN-E", "Affluent"),
    ("MAC000104", "Std", "ACORN-F", "Comfortable"),
    ("MAC000105", "ToU", "ACORN-H", "Comfortable"),
    ("MAC000106", "Std", "ACORN-J", "Comfortable"),
    ("MAC000107", "ToU", "ACORN-L", "Adversity"),
    ("MAC000108", "Std", "ACORN-Q", "Adversity"),
]

BASE_LOAD = {"Affluent": 0.32, "Comfortable": 0.24, "Adversity": 0.18}


def slot_kwh(rng: random.Random, group: str, tariff: str, slot: int) -> float:
    hour = slot / 2
    # morning bump around 07:30, evening peak around 18:30
    shape = 1 + 0.6 * math.exp(-((hour - 7.5) ** 2) / 2) + 1.4 * math.exp(-((hour - 18.5) ** 2) / 3)
    if tariff == "ToU" and 16 <= hour < 19:
        shape *= 0.8  # time-of-use customers shift load away from the peak price window
    return round(BASE_LOAD[group] * shape * rng.uniform(0.85, 1.15), 3)


def main() -> None:
    rng = random.Random(42)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    with open(OUT_DIR / "dim_households.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["LCLID", "STDORTOU", "ACORN", "ACORN_GROUPED"])
        w.writerows(HOUSEHOLDS)

    readings, daily = [], []
    for lclid, tariff, _acorn, group in HOUSEHOLDS:
        for d in range(DAYS):
            day = START + timedelta(days=d)
            values = []
            for s in range(SLOTS_PER_DAY):
                kwh = slot_kwh(rng, group, tariff, s)
                values.append(kwh)
                readings.append([lclid, (day + timedelta(minutes=30 * s)).strftime("%Y-%m-%d %H:%M:%S"), kwh])
            daily.append([lclid, day.strftime("%Y-%m-%d"), round(sum(values), 3),
                          round(sum(values) / len(values), 4), max(values)])

    # Dirty rows that the staging layer must filter out
    readings.append(["MAC000101", "2013-01-01 00:15:00", -0.5])   # negative meter glitch
    readings.append(["", "2013-01-01 00:00:00", 0.2])              # missing meter id
    daily.append(["MAC000108", "2013-01-04", "", "", ""])          # incomplete daily row

    with open(OUT_DIR / "fact_energy_readings.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["LCLID", "TSTP", "ENERGY_KWH_PER_HR"])
        w.writerows(readings)

    with open(OUT_DIR / "agg_daily_consumption.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["LCLID", "DATE", "TOTAL_KWH_DAY", "AVG_KWH_PER_SLOT", "PEAK_KWH"])
        w.writerows(daily)

    print(f"Wrote {len(HOUSEHOLDS)} households, {len(readings)} readings, {len(daily)} daily rows to {OUT_DIR}")


if __name__ == "__main__":
    main()
