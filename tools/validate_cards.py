"""Check card JSON files against docs/CARD_SPEC.md.

Usage: python3 tools/validate_cards.py data/cards_v2/sanctum.json [more files...]
Prints problems and a summary; exit code 1 if any problem.
"""
import json
import re
import sys

FAITHS = ["sanctum", "abyss", "wild", "revel", "lyceum", "machine"]
MANA = {"sanctum": "W", "abyss": "B", "wild": "G", "revel": "R", "lyceum": "U", "machine": "C"}
KEYWORD_OWNER = {
    "flying": "sanctum", "martyr": "sanctum", "lifelink": "sanctum", "sanctified": "sanctum",
    "deathtouch": "abyss", "dread": "abyss",
    "trample": "wild", "reach": "wild", "regenerate": "wild",
    "haste": "revel", "first_strike": "revel",
    "vigilance": "lyceum", "defender": "lyceum", "unmoved": "lyceum",
}
ACTION_OWNERS = {
    "heal": ["sanctum"], "pacify": ["sanctum"],
    "drain": ["abyss"], "discard_enemy": ["abyss"], "reanimate": ["abyss"],
    "fight": ["wild"], "destroy_relic": ["wild"],
    "rummage": ["revel"],
    "bounce": ["lyceum"], "tap": ["lyceum"], "freeze": ["lyceum"], "foresight": ["lyceum"], "tax": ["lyceum"],
    "snare": ["machine"], "upkeep_cost": ["machine"],
    "attach": ["wild", "machine"],
    "damage": ["revel", "machine"],
    "destroy": ["sanctum", "abyss", "wild"],
    "add_mana": ["wild", "machine"],
    "draw": ["lyceum", "abyss"],
    "summon": ["wild", "abyss", "machine"],
    "buff": FAITHS, "lose_life": FAITHS,
}
CONDITION_OWNER = {"grace": "sanctum", "composure": "lyceum", "rooted": "wild", "carouse": "revel", "bloodied": "abyss"}
TRIGGERS = ["enter", "death", "upkeep", "attack", "cast", "idle", "ally_enter"]
TARGETS = ["", "any_enemy", "enemy_creature", "own_creature", "enemy_relic", "own_grave_creature", "self_player", "enemy_player", "self",
           "all_enemy_creatures", "all_own_creatures", "other_own_creatures", "all_creatures"]
STATICS = {"anthem": None, "keyword": None, "assembly": "machine", "cost_reduce": None, "kinship": None}
COUNTS = {"common": 29, "uncommon": 20, "rare": 12, "mythic": 4}
DASHES = re.compile("[‒–—―−]")
WOMEN = [" she ", " her ", " hers ", "woman", "maiden", "lady", "queen", "sister", "mother", "wife", "daughter"]
FIGHTERS = ["Soldier", "Knight", "Paladin", "Warrior", "Duelist", "Assassin", "Hoplite", "Guard", "Sentinel", "Lancer", "Berserker", "Champion"]

problems = []


def bad(cid, msg):
    problems.append("%s: %s" % (cid, msg))


def check_effect(cid, faith, e, where, owners):
    a = e.get("action")
    if a not in ACTION_OWNERS:
        bad(cid, "%s unknown action %r" % (where, a))
        return
    ok = [f for f in owners if f in ACTION_OWNERS[a]]
    if not ok:
        bad(cid, "%s action %s not owned by %s" % (where, a, owners))
    if where == "effect" and e.get("trigger") not in TRIGGERS:
        bad(cid, "bad trigger %r" % e.get("trigger"))
    if e.get("trigger") == "idle" and "revel" not in owners:
        bad(cid, "idle is Revel only")
    if e.get("target", "") not in TARGETS:
        bad(cid, "%s bad target %r" % (where, e.get("target")))
    c = e.get("condition")
    if c and CONDITION_OWNER.get(c) not in owners:
        bad(cid, "condition %s not owned" % c)
    if a == "buff":
        if e.get("power", 0) < 0 or e.get("toughness", 0) < 0:
            if "abyss" not in owners:
                bad(cid, "shrink (negative buff) is Pact only")
        if e.get("target") == "own_creature" and e.get("power", 0) > 0 and e.get("duration", "turn") == "turn" \
                and "wild" not in owners and where == "effect" and e.get("trigger") == "cast":
            bad(cid, "single-creature pump spells belong to the Old Ways")
    if a == "damage" and e.get("target") in ["any_enemy", "enemy_player"] and "revel" not in owners:
        bad(cid, "damage to players is Revel only")
    if a == "destroy" and faith == "sanctum" and not e.get("tapped") and "abyss" not in owners and "wild" not in owners:
        bad(cid, "Church destroy must target tapped creatures")
    if a == "destroy" and faith == "wild" and not e.get("flying") and "abyss" not in owners and "sanctum" not in owners:
        bad(cid, "Old Ways destroy must target fliers")
    if a == "summon":
        tok = e.get("token", {})
        if not tok.get("name"):
            bad(cid, "token needs a name")
        for k in tok.get("keywords", []):
            if KEYWORD_OWNER.get(k) not in owners:
                bad(cid, "token keyword %s not owned" % k)


def check_card(c, owners_override=None):
    cid = c.get("id", "?")
    faith = c.get("faction")
    if faith not in FAITHS:
        bad(cid, "bad faction")
        return
    owners = owners_override or [faith] + ([c["faction2"]] if c.get("faction2") else [])
    if c.get("type") == "land":
        if not isinstance(c.get("produces"), list) or len(c["produces"]) != 2:
            bad(cid, "dual land needs two colours in produces")
        if not c.get("text") or not c.get("flavor"):
            bad(cid, "land needs text and flavour")
        return
    for k in ["name", "rarity", "type", "text", "flavor"]:
        if not c.get(k):
            bad(cid, "missing " + k)
    if c.get("type") not in ["creature", "spell", "relic"]:
        bad(cid, "bad type")
    if c.get("rarity") not in COUNTS:
        bad(cid, "bad rarity")
    for k, v in c.get("cost", {}).items():
        if k not in ["W", "U", "B", "R", "G", "C", "generic"] or not isinstance(v, int):
            bad(cid, "bad cost %s" % k)
        if k != "generic" and k not in [MANA[f] for f in owners]:
            bad(cid, "cost symbol %s not of its faith" % k)
    if c.get("type") == "creature":
        if not isinstance(c.get("power"), int) or not isinstance(c.get("toughness"), int) or c["toughness"] < 1:
            bad(cid, "creature needs power/toughness")
        if not c.get("subtype"):
            bad(cid, "creature needs subtype")
    for k in c.get("keywords", []):
        if k not in KEYWORD_OWNER:
            bad(cid, "unknown keyword %s" % k)
        elif KEYWORD_OWNER[k] not in owners and not (k == "flying" and "lyceum" in owners and "Bird" in c.get("subtype", "")):
            bad(cid, "keyword %s belongs to %s" % (k, KEYWORD_OWNER[k]))
    if "flying" in c.get("keywords", []) and "sanctum" not in owners and "lyceum" in owners and c.get("power", 0) > 2:
        bad(cid, "Stoa birds fly small (power 2 at most)")
    att = c.get("attach")
    if att:
        if c.get("type") != "relic":
            bad(cid, "only relics attach")
        if att == "aura" and "wild" not in owners:
            bad(cid, "auras are Old Ways")
        if att == "equipment" and "machine" not in owners:
            bad(cid, "equipment is Technocracy")
        if att == "aura" and not any(e.get("action") == "attach" and e.get("trigger") == "enter" for e in c.get("effects", [])):
            bad(cid, "an aura needs an enter attach effect on own_creature")
        if att == "equipment" and not c.get("equip"):
            bad(cid, "equipment needs an equip cost")
        for k in c.get("grants", {}).get("keywords", []):
            ok = KEYWORD_OWNER.get(k) in owners or (att == "equipment" and k in ["first_strike", "trample", "vigilance", "reach"])
            if not ok:
                bad(cid, "granted keyword %s not allowed" % k)
    for e in c.get("effects", []):
        check_effect(cid, faith, e, "effect", owners)
        if c.get("type") == "spell" and e.get("trigger") != "cast":
            bad(cid, "spell effects need trigger cast")
    if c.get("speed") not in [None, "instant"]:
        bad(cid, "speed must be 'instant' or absent")
    if c.get("speed") and c.get("type") != "spell":
        bad(cid, "only spells can be instants")
    for e in c.get("effects", []):
        if e.get("trigger") == "ally_enter" and not e.get("ally_subtype"):
            bad(cid, "ally_enter needs ally_subtype")
    for ab in c.get("abilities", []):
        cost = ab.get("cost", {})
        if cost.get("sacrifice") in ["other", "self"] and "abyss" not in owners and not (cost.get("sacrifice") == "self" and "machine" in owners):
            bad(cid, "sacrifice costs are Pact only")
        if not ab.get("text"):
            bad(cid, "ability needs text")
        for e in ab.get("effects", []):
            check_effect(cid, faith, e, "ability", owners)
    for s in c.get("statics", []):
        kind = s.get("static")
        if kind not in STATICS:
            bad(cid, "unknown static %r" % kind)
        elif STATICS[kind] and STATICS[kind] not in owners:
            bad(cid, "static %s is %s only" % (kind, STATICS[kind]))
        if kind == "cost_reduce" and not s.get("subtype") and "machine" not in owners:
            bad(cid, "cost_reduce without a subtype is Technocracy only")
        if kind == "kinship" and not s.get("subtype"):
            bad(cid, "kinship needs a subtype")
        if kind == "keyword" and KEYWORD_OWNER.get(s.get("keyword")) not in owners:
            bad(cid, "static keyword %s not owned" % s.get("keyword"))
        if kind == "anthem" and s.get("scope") in ["own_creatures", "other_own_creatures"] and "sanctum" not in owners and not s.get("subtype"):
            bad(cid, "team-wide anthems are Church only (other faiths: self scope or a subtype filter)")
        if kind == "anthem" and s.get("scope") == "enemy_creatures" and "abyss" not in owners:
            bad(cid, "enemy shrink anthem is Pact only")
        cnd = s.get("condition")
        if cnd and CONDITION_OWNER.get(cnd) not in owners:
            bad(cid, "condition %s not owned" % cnd)
    if c.get("overclock") and "machine" not in owners:
        bad(cid, "overclock is Technocracy only")
    for e in c.get("overclock", {}).get("effects", []):
        check_effect(cid, faith, e, "overclock", owners)
    text = " ".join(str(c.get(k, "")) for k in ["name", "text", "flavor", "subtype"])
    if DASHES.search(text) or "--" in text:
        bad(cid, "contains a dash")
    if "themself" in text.lower():
        bad(cid, "singular they")
    for w in ["worst", "your best", "strongest"]:
        if w in str(c.get("text", "")).lower():
            bad(cid, "the player chooses: no '%s' in rules text" % w)
    st = c.get("subtype", "")
    words = " " + (str(c.get("flavor", "")) + " " + str(c.get("name", "")) + " " + str(c.get("text", ""))).lower() + " "
    if any(f in st for f in FIGHTERS):
        for w in WOMEN:
            if w in words:
                bad(cid, "fighter described as a woman (%s)" % w.strip())
    if "Angel" in st:
        for w in [" she ", " her ", " it ", " its "]:
            if w in words:
                bad(cid, "angel must be 'he' (%s)" % w.strip())


def main():
    files = sys.argv[1:]
    for path in files:
        cards = json.load(open(path, encoding="utf-8"))
        ids = set()
        names = set()
        counts = {}
        types = {}
        faith = None
        for c in cards:
            if c.get("id") in ids:
                bad(c.get("id"), "duplicate id")
            ids.add(c.get("id"))
            if c.get("name") in names:
                bad(c.get("id"), "duplicate name")
            names.add(c.get("name"))
            counts[c.get("rarity")] = counts.get(c.get("rarity"), 0) + 1
            types[c.get("type")] = types.get(c.get("type"), 0) + 1
            faith = c.get("faction")
            check_card(c)
        print("%s: %d cards %s %s" % (path, len(cards), counts, types))
        if faith == "lyceum":
            fliers = [c["id"] for c in cards if "flying" in c.get("keywords", [])]
            if len(fliers) > 2:
                problems.append("%s: the Stoa may have at most 2 fliers, found %s" % (path, fliers))
        if "gold" not in path and "lands" not in path:
            for r, n in COUNTS.items():
                if counts.get(r, 0) != n:
                    problems.append("%s: expected %d %s, found %d" % (path, n, r, counts.get(r, 0)))
    for p in problems:
        print("PROBLEM", p)
    print("%d problem(s)" % len(problems))
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
