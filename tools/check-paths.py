"""Checks that every file path in our prototypes exists (headless runs don't load graphics, so they miss this).

Usage: run Factorio with --dump-data (same --config / --mod-directory as the harness), then
  python tools/check-paths.py <write-data>/script-output/data-raw-dump.json
Checks prototypes whose name starts with hf-, ht- or contains "cheat". Exit code 1 if anything is missing.
"""
import json, os, re, sys

GAME_DATA = "C:/Program Files (x86)/Steam/steamapps/common/Factorio/data/"
MODS = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + "/../"
OUR_MODS = {"Hostile-fauna", "Hostile-territory", "cheating-mod"}
FILE = re.compile(r"^__([^_].*?)__/(.*\.(png|jpg|ogg|wav|voc))$")


def walk(value, owner, found):
    if isinstance(value, dict):
        for v in value.values():
            walk(v, owner, found)
    elif isinstance(value, list):
        for v in value:
            walk(v, owner, found)
    elif isinstance(value, str):
        m = FILE.match(value)
        if m:
            mod, path = m.group(1), m.group(2)
            base = MODS + mod + "/" if mod in OUR_MODS else GAME_DATA + mod + "/"
            found.append((owner, value, os.path.exists(base + path)))


def main():
    dump = json.load(open(sys.argv[1], encoding="utf8"))
    found = []
    for type_name, prototypes in dump.items():
        for name, prototype in prototypes.items():
            if name.startswith(("hf-", "ht-")) or "cheat" in name:
                walk(prototype, type_name + "/" + name, found)
    missing = sorted({(o, v) for o, v, ok in found if not ok})
    print(f"checked {len(found)} paths, missing {len(missing)}")
    for owner, value in missing:
        print(f"  {owner}: {value}")
    sys.exit(1 if missing else 0)


main()
