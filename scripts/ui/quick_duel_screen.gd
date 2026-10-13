class_name QuickDuelScreen
extends Control
## Quick duel (main menu): playtest decks without a game. Pick your deck and the opponent's from
## your practice decks (built from every card in the game), the theme decks of the wanderers and
## the two-faith decks; set the life; duel. Nothing of your saved game is touched.

signal duel(mine: Dictionary, theirs: Dictionary, life: int)
signal edit_decks
signal back

const SAVE := "user://quickduel.json"

var premade: Array = []
const RANDOM := -1            # "a random deck", drawn when the duel starts
const RANDOM_KEY := "__random__"
var mine := 0                 # index into _all() for your side (RANDOM: drawn at the duel)
var theirs := 0               # and the opponent's
var life := 15
var _lists := {}              # side -> VBoxContainer
var _life_lbl: Label


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	premade = DeckTools.premade_decks()
	var st := load_state()
	life = int(st.get("life", Hero.BASE_LIFE))
	var all := _all()
	mine = RANDOM if st.get("mine", "") == RANDOM_KEY else clampi(_find(String(st.get("mine", "")), 0), 0, all.size() - 1)
	theirs = RANDOM if st.get("theirs", "") == RANDOM_KEY else clampi(_find(String(st.get("theirs", "")), mini(1, all.size() - 1)), 0, all.size() - 1)
	var root := VBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", UIKit.SP_1)
	add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.GAP)
	root.add_child(head)
	head.add_child(UIKit.corner_space(22, UIKit.GAP))
	var t := UIKit.title("Quick duel", UIKit.FS_HEADING + 4)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UIKit.button("Back", func():
		back.emit()
		queue_free(), 120))
	var note := UIKit.label(I18n.t("Practice only: no life, gold or cards of your game are at stake. Your practice decks may use every card in the game."), UIKit.FS_MIN, UIKit.DIM, true)
	root.add_child(note)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", UIKit.SP_2)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	for side in 2:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		cols.add_child(col)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UIKit.GAP)
		col.add_child(row)
		var h := UIKit.title("Your deck" if side == 0 else "Opponent", UIKit.FS_BODY + 2)
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(h)
		var sd: int = side
		var view := UIKit.button("View", func(): _view(sd), 100)
		view.name = "View%d" % side
		row.add_child(view)
		if side == 0:
			var ed := UIKit.button("Build decks", func():
				save_state()
				edit_decks.emit(), 150)
			ed.name = "BuildDecks"
			row.add_child(ed)
		var sc := ScrollContainer.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		col.add_child(sc)
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 4)
		sc.add_child(box)
		DragScroll.attach(self, sc)
		_lists[side] = box
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", UIKit.GAP)
	root.add_child(foot)
	var ll := UIKit.label("Starting life", UIKit.FS_BODY, UIKit.TEXT)
	ll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(ll)
	foot.add_child(UIKit.button("−", func(): _set_life(life - 5), UIKit.TARGET_W))
	_life_lbl = UIKit.label("", UIKit.FS_BODY, UIKit.TEXT)
	_life_lbl.custom_minimum_size.x = 48
	_life_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_life_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(_life_lbl)
	foot.add_child(UIKit.button("+", func(): _set_life(life + 5), UIKit.TARGET_W))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)
	var go := UIKit.primary_button("Duel", func():
		var a := _all()
		save_state()
		var pick := _resolve()
		duel.emit(a[pick[0]], a[pick[1]], life), 200)
	go.name = "Duel"
	foot.add_child(go)
	_set_life(life)
	_fill()


## Your practice decks, then the theme decks, then the two-faith decks.
func _all() -> Array:
	var out: Array = []
	for d in load_state().get("decks", []):
		var cards := {}
		for k in d.get("cards", {}):
			cards[String(k)] = int(d["cards"][k])      # JSON gives the counts back as floats
		if DeckTools.count(cards) >= 40:
			var fs := DeckTools.best_factions(cards, 1)
			out.append({"name": String(d.get("name", "Practice deck")), "cards": cards,
				"faith": fs[0] if not fs.is_empty() else "sanctum", "kind": "mine"})
	return out + premade


## The two decks for the duel: a Random side draws any deck (the two sides never the same one).
func _resolve() -> Array:
	var n := _all().size()
	var a := mine if mine != RANDOM else randi() % n
	var b := theirs
	if b == RANDOM:
		b = randi() % n
		if n > 1:
			while b == a:
				b = randi() % n
	if mine == RANDOM and n > 1:
		while a == b:
			a = randi() % n
	return [a, b]


func _find(nm: String, fallback: int) -> int:
	var a := _all()
	for i in a.size():
		if a[i]["name"] == nm:
			return i
	return fallback


func _set_life(v: int) -> void:
	life = clampi(v, 5, 40)
	_life_lbl.text = str(life)


func _fill() -> void:
	var a := _all()
	for side in 2:
		var box: VBoxContainer = _lists[side]
		UIKit.clear(box)
		# first: a random deck, drawn from all of them when the duel starts
		var sdr: int = side
		var rb := UIKit.button("🎲  " + I18n.t("Random deck"), func():
			if sdr == 0:
				mine = RANDOM
			else:
				theirs = RANDOM
			_fill(), 0)
		rb.name = "Random%d" % side
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		rb.add_theme_font_size_override("font_size", UIKit.FS_SECONDARY)
		rb.tooltip_text = I18n.t("Any of the decks below, drawn when the duel starts")
		UIKit.set_selected(rb, (mine if side == 0 else theirs) == RANDOM)
		box.add_child(rb)
		var last_kind := ""
		for i in a.size():
			var d: Dictionary = a[i]
			if d["kind"] != last_kind:
				last_kind = d["kind"]
				var g: String = {"mine": "Your practice decks", "proto": "The faith decks (60 cards)", "theme": "Theme decks (the wanderers' decks)", "pair": "Two-faith decks"}[last_kind]
				box.add_child(UIKit.label(g, UIKit.FS_SECONDARY, UIKit.GOLD))
			var ix: int = i
			var sd: int = side
			var b := UIKit.button(String(d["name"]), func():
				if sd == 0:
					mine = ix
				else:
					theirs = ix
				_fill(), 0)
			b.name = "Deck%d_%d" % [side, i]
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", UIKit.FS_SECONDARY)
			b.clip_text = true
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			UIKit.set_selected(b, i == (mine if side == 0 else theirs))
			box.add_child(b)
		if not a.any(func(x): return x["kind"] == "mine") and side == 0:
			var hint := UIKit.label(I18n.t("Build decks to make your own from every card."), UIKit.FS_MIN, UIKit.DIM, true)
			box.add_child(hint)
			box.move_child(hint, 1)


## Read the chosen deck card by card.
func _view(side: int) -> void:
	var ix := mine if side == 0 else theirs
	if ix == RANDOM:
		return              # a random deck is only known when the duel starts
	var d: Dictionary = _all()[ix]
	var ids: Array = []
	var keys: Array = d["cards"].keys()
	keys.sort_custom(func(x, y): return int(CardDB.get_card(x).get("mana_value", 0)) < int(CardDB.get_card(y).get("mana_value", 0)))
	for id in keys:
		if not CardDB.is_basic_land(id):
			ids.append(id)
	if not ids.is_empty():
		CardViewer.open(self, ids, 0)


# ------------------------------------------------------------------ saved practice state

static func load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	return d if typeof(d) == TYPE_DICTIONARY else {}


func save_state() -> void:
	var st := load_state()
	var a := _all()
	st["mine"] = RANDOM_KEY if mine == RANDOM else a[mine]["name"]
	st["theirs"] = RANDOM_KEY if theirs == RANDOM else a[theirs]["name"]
	st["life"] = life
	write_state(st)


static func write_state(st: Dictionary) -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(st))
