"""Collect every English string the game shows, for translation.

Writes tools/i18n_keys.json: {"group": [{"key": ..., "note": ...}, ...]}.
Run:  python3 tools/i18n_extract.py
Then translate into data/i18n/pt.json and data/i18n/es.json ({English: translation}).
`python3 tools/i18n_extract.py --missing` lists keys that are not translated yet.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
LIT = re.compile(r'"((?:[^"\\]|\\.)*)"')
SKIP_FILES = ("i18n.gd",)


def ui_like(s):
    if "://" in s or s.startswith("res:") or s.startswith("user:"):
        return False
    if not re.search(r"[A-Za-z]{2,}", s):
        return False
    if re.fullmatch(r"[a-z0-9_]+", s):          # identifiers / dict keys
        return False
    if re.fullmatch(r"[A-Za-z]+_[A-Za-z_]+", s):
        return False
    if s.startswith("[color") or s.startswith("%s") and len(s) < 6:
        return False
    if re.fullmatch(r"[A-Z][a-z]+[A-Z]\w*", s):  # CamelCase node/class names
        return False
    return True


def unescape(s):
    return bytes(s, "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")


def code_strings():
    found = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "scripts/**/*.gd"), recursive=True)):
        if f.endswith(SKIP_FILES):
            continue
        rel = os.path.relpath(f, ROOT)
        for line in open(f, encoding="utf-8"):
            st = line.strip()
            if st.startswith("#") or "push_warning" in st or st.startswith("print(") or "load(" in st or "preload(" in st:
                continue
            for m in LIT.finditer(line):
                raw = m.group(1)
                try:
                    s = unescape(raw)
                except Exception:
                    s = raw
                if ui_like(s):
                    found.setdefault(s, rel)
    return found


def main():
    groups = {"interface": [], "cards": [], "world": [], "music": [], "generated": []}
    seen = set()

    def add(group, key, note=""):
        if not key or key in seen:
            return
        seen.add(key)
        groups[group].append({"key": key, "note": note})

    # strings built at runtime with capitalize() / data words
    for w in ["Creature", "Spell", "Relic", "Land", "Common", "Uncommon", "Rare", "Mythic", "Basic", "Token", "All",
              "common", "uncommon", "rare", "mythic",
              "Damage", "Heal", "Drain", "Draw", "Discard Enemy", "Buff", "Destroy", "Bounce", "Tap", "Summon",
              "Add Mana", "Lose Life", "Reanimate", "Anthem", "Menu", "Combat", "Main phase", "Main phase 2",
              "Duel over", "Starter deck", "Foil", "Tap: add one %s mana."]:
        add("generated", w, "word shown in the interface (capitalised data value)")

    for s, where in code_strings().items():
        add("interface", s, where)

    for f in ["sanctum", "abyss", "wild", "revel", "lyceum", "machine", "gold", "lands"]:
        path = os.path.join(ROOT, "data/cards/%s.json" % f)
        if not os.path.exists(path):
            continue
        for c in json.load(open(path, encoding="utf-8")):
            add("cards", c["name"], "card name (%s, %s)" % (f, c["type"]))
            add("cards", c.get("subtype", ""), "card subtype")
            add("cards", c.get("text", ""), "rules text of " + c["name"])
            add("cards", c.get("flavor", ""), "flavour text of " + c["name"])
            effs = list(c.get("effects", [])) + list(c.get("overclock", {}).get("effects", []))
            for ab in c.get("abilities", []):
                add("cards", ab.get("text", ""), "activated ability text of " + c["name"])
                effs += ab.get("effects", [])
            for e in effs:
                if "token" in e:
                    add("cards", e["token"]["name"], "token creature name")
                    add("cards", e["token"].get("subtype", ""), "token subtype")
    for short in ["Church", "Covenant", "Old Ways", "Revel", "Stoa", "Technocracy"]:
        add("cards", "Tap: add one %s mana." % short, "basic land rules text")

    world = json.load(open(os.path.join(ROOT, "data/world.json"), encoding="utf-8"))
    for c in world["cities"]:
        add("world", c["description"], "description of the city " + c["name"])
        for n in c["npcs"]:
            add("world", n.get("title", ""), "title of a townsperson")
            add("world", n["name"], "name of a townsperson (translate the title word, keep the name)")
    for l in world["lairs"]:
        add("world", l["name"], "name of a lair (dungeon)")
        add("world", l["boss"], "name of a lair boss")
    for m in world["missions"].values():
        add("world", m["title"], "mission title")
        add("world", m.get("text", ""), "mission description")

    for t in json.load(open(os.path.join(ROOT, "data/music.json"), encoding="utf-8")):
        add("music", t["title"], "title of a %s piece of music (%s)" % (t["kind"], t["faction"]))

    out = os.path.join(ROOT, "tools/i18n_keys.json")
    json.dump(groups, open(out, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    total = sum(len(v) for v in groups.values())
    print("keys:", total, {k: len(v) for k, v in groups.items()})

    if "--missing" in sys.argv:
        for code in ["pt", "es"]:
            path = os.path.join(ROOT, "data/i18n/%s.json" % code)
            table = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}
            missing = [k for k in seen if k not in table]
            print(code, "missing", len(missing))
            for k in missing[:40]:
                print("   ", repr(k))
            notes = {}
            for g in groups.values():
                for item in g:
                    notes[item["key"]] = item["note"]
            json.dump([{"key": k, "note": notes.get(k, "")} for k in missing],
                      open(os.path.join(ROOT, "tools/i18n_missing_%s.json" % code), "w", encoding="utf-8"), indent=1, ensure_ascii=False)


if __name__ == "__main__":
    main()
