"""Summary of challenge telemetry CSVs (oil-ring-challenge-plan.md, balance pass).

Per phase / surge: length, brain %, HP, damage per second, units alive, most touching, queen biters per second,
queens, queen level. Then the pull-backs and the seconds with a damage spike (> 4 HP lost in one second).

    python tools/ht-telemetry-summary.py 1943-t8.csv [more.csv ...]

Names without a folder are read from %APPDATA%/Factorio/script-output/ht-telemetry.
"""
import csv
import os
import sys

BASE = os.path.expandvars(r"%APPDATA%\Factorio\script-output\ht-telemetry")
SPIKE = 4


def num(v):
    try:
        return float(v)
    except ValueError:
        return 0.0


def summary(path):
    rows = [r for r in csv.DictReader(open(path)) if r["second"].isdigit()]
    print(f"== {os.path.basename(path)}: {len(rows)} s, ended at {rows[-1]['hp']} HP, brain {rows[-1]['brain_pct']} %")
    segs = []
    for r in rows:
        key = (r["phase"], r["surge"])
        if not segs or segs[-1][0] != key:
            segs.append((key, []))
        segs[-1][1].append(r)
    print(f"{'phase':8}{'surge':>6}{'from':>6}{'s':>5}{'brain %':>10}{'HP':>10}{'HP/s':>6}{'alive':>6}{'touch':>6}"
          f"{'qbit/s':>7}{'queens':>7}{'level':>6}")
    for (phase, surge), rs in segs:
        a, b, n = rs[0], rs[-1], len(rs)
        print(f"{phase:8}{surge:>6}{a['second']:>6}{n:>5}{a['brain_pct'] + '>' + b['brain_pct']:>10}"
              f"{a['hp'] + '>' + b['hp']:>10}{(num(a['hp']) - num(b['hp'])) / n:6.2f}"
              f"{sum(num(r['alive']) for r in rs) / n:6.0f}{max(num(r['touching']) for r in rs):6.0f}"
              f"{(num(b['queen_spawned']) - num(a['queen_spawned'])) / n:7.1f}{max(num(r['queens']) for r in rs):7.0f}"
              f"{sum(num(r['queen_level']) for r in rs) / n:6.1f}")
    prev = None
    for r in rows:
        if r["regroup"] != prev and prev is not None:
            print(f"  regroup {r['regroup']} at {r['second']} s (HP {r['hp']}, touching {r['touching']}, brain {r['brain_pct']} %)")
        prev = r["regroup"]
    hp = [num(r["hp"]) for r in rows]
    spikes = [(rows[i]["second"], hp[i - 1] - hp[i], rows[i]["touching"], rows[i]["max_hit_by"])
              for i in range(1, len(rows)) if hp[i - 1] - hp[i] > SPIKE]
    lost = hp[0] - hp[-1]
    in_spikes = sum(s[1] for s in spikes)
    print(f"  spikes (> {SPIKE} HP/s): " + ", ".join(f"{s}s -{d:.0f} ({t} touching, {by})" for s, d, t, by in spikes))
    print(f"  lost {lost:.0f} HP, {in_spikes:.0f} of it in {len(spikes)} spike seconds")


for name in sys.argv[1:]:
    summary(name if os.path.dirname(name) else os.path.join(BASE, name))
