class_name CardDatabase
extends Control
## Every card in the game (the six faiths, gold cards and lands; no tokens) to browse.
## Filters: faith group, rarity, type and a search on name, subtype and rules text.
## Sorted by faith, then rarity, then mana value, then name. Tap a card to read it up close
## and leaf through the cards currently shown.
##
## Thumbnails are made once per card and kept; their pictures load on a thread and they are
## made a few per frame, so opening never stalls, and filtering only hides, shows and reorders.

signal closed

const GROUPS := ["all", "sanctum", "abyss", "wild", "revel", "lyceum", "machine", "gold", "lands"]
const TYPES := ["Any type", "Creature", "Sorcery", "Instant", "Relic", "Land"]
const RARITIES := ["Any rarity", "Basic", "Common", "Uncommon", "Rare", "Mythic"]
const RARITY_ORDER := ["basic", "common", "uncommon", "rare", "mythic"]
const FRAME_MS := 8               # time spent making thumbnails per frame
const AHEAD := 40                 # pictures loaded ahead of the thumbnails being made
const GAP := 14

var f_group := "all"
var f_type := 0
var f_rarity := 0
var f_text := ""

var all_ids: Array = []           # every card, already in display order
var shown: Array = []             # ids passing the filters, in order
var views := {}                   # id -> CardView (made on demand, then reused)
var scale_k := 0.6
var compact := false              # phone-sized canvas: one row of controls, larger thumbnails

var grid: GridContainer
var scroll: ScrollContainer
var count_label: Label
var search: LineEdit
var group_btns := {}
var type_opt: OptionButton
var rarity_opt: OptionButton
var _gen := 0                     # bumps on every refilter, so a stale fill loop stops
var _sort_cache := {}
var _requested := {}              # art paths asked of the threaded loader
var drag: DragScroll              # finger or mouse drag scrolling over the cards, with a glide


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(Backdrop.create("rings"))
	var vp := get_viewport_rect().size
	compact = vp.y < 600.0
	var v := VBoxContainer.new()
	UIKit.content_rect(v)
	v.add_theme_constant_override("separation", UIKit.SP_1)
	add_child(v)

	# --- heading: title, count, back (on a phone the filters share this row, see below)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.SP_1 if compact else UIKit.GAP)
	v.add_child(head)
	head.add_child(UIKit.corner_space(22, UIKit.SP_1 if compact else UIKit.GAP))
	var tl := UIKit.title("Card Database", UIKit.FS_HEADING if compact else UIKit.FS_TITLE - 2)
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(tl)
	count_label = UIKit.label("", UIKit.FS_SECONDARY, UIKit.DIM)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	count_label.visible = not compact
	head.add_child(count_label)
	var back := UIKit.button("Back", _back, 110 if compact else 140)
	back.add_theme_font_size_override("font_size", UIKit.FS_BODY)

	# --- faith groups: All, the six faiths, Gold, Lands
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 4)
	var bg := ButtonGroup.new()
	for g in GROUPS:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = bg
		b.text = _group_name(g)
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", UIKit.FS_SECONDARY)
		var looks := {"normal": "button", "hover": "hover", "pressed": "pressed", "focus": "hover"}
		for st in looks:
			b.add_theme_stylebox_override(st, Tapestry.stylebox(looks[st], 4))     # narrow margins: room for the name
		if Factions.DATA.has(g):
			b.add_theme_color_override("font_color", UIKit.faction_ink(g))
			b.add_theme_color_override("font_pressed_color", UIKit.faction_ink(g))
		elif g == "gold":
			b.add_theme_color_override("font_color", Color(0.55, 0.38, 0.05))
			b.add_theme_color_override("font_pressed_color", Color(0.55, 0.38, 0.05))
		b.button_pressed = g == f_group
		var gg: String = g
		b.toggled.connect(func(on):
			if on and f_group != gg:
				f_group = gg
				_refilter())
		group_btns[g] = b
		frow.add_child(b)

	# --- rarity, type, search, clear: their own row, or the title's row on a phone
	var srow := head
	if not compact:
		head.add_child(back)
		srow = HBoxContainer.new()
		srow.add_theme_constant_override("separation", UIKit.SP_1)
	rarity_opt = _option(srow, RARITIES, func(i): f_rarity = i)
	type_opt = _option(srow, TYPES, func(i): f_type = i)
	search = LineEdit.new()
	search.placeholder_text = "Search" if compact else "Search name, subtype or text"
	search.tooltip_text = I18n.t("Search name, subtype or text")
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.size_flags_stretch_ratio = 1.6
	search.custom_minimum_size = Vector2(120, UIKit.TARGET)
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	search.text_changed.connect(func(t):
		f_text = t.strip_edges().to_lower()
		_refilter())
	srow.add_child(search)
	var clr := UIKit.button("Clear" if compact else "Clear filters", _clear_filters, UIKit.TARGET_W)
	clr.name = "ClearFilters"
	clr.tooltip_text = I18n.t("Clear filters")
	clr.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	srow.add_child(clr)
	if compact:
		head.add_child(back)
	v.add_child(frow)
	if not compact:
		v.add_child(srow)

	# --- the cards
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	v.add_child(scroll)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	scroll.add_child(grid)
	scroll.resized.connect(_fit_columns)
	drag = DragScroll.attach(self, scroll, _popup_open)

	# about 150 px wide on a phone; on a desktop two and a half rows fit the screen
	scale_k = 0.75 if compact else clampf((vp.y - 300.0) / (CardView.BASE.y * 2.5), 0.5, 0.8)
	_collect()
	_fit_columns()
	_refilter()


func _option(parent: Control, items: Array, cb: Callable) -> OptionButton:
	var o := OptionButton.new()
	for it in items:
		o.add_item(it)
	o.custom_minimum_size = Vector2(130 if compact else 170, UIKit.TARGET)
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o.clip_text = true
	o.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	o.item_selected.connect(func(i):
		cb.call(i)
		_refilter())
	parent.add_child(o)
	return o


func _group_name(g: String) -> String:
	match g:
		"all": return "All"
		"gold": return "Gold"
		"lands": return "Lands"
	return Factions.info(g)["short"]


## The display group of a card: its faith, "gold" (two faiths) or "lands".
static func group_of(c: Dictionary) -> String:
	if c.get("type", "") == "land":
		return "lands"
	if String(c.get("faction2", "")) != "":
		return "gold"
	return String(c.get("faction", "machine"))


func _collect() -> void:
	all_ids.clear()
	for id in CardDB.cards:
		if String(id).begins_with("t_"):
			continue          # rules-test cards registered by the test runner
		var c := CardDB.get_card(id)
		if c.get("rarity", "") == "token" or c.get("proto", false):
			continue
		all_ids.append(id)
		var lname := I18n.t(String(c.get("name", "")))
		var g := group_of(c)
		# gold cards and lands also keep their faiths' order within a rarity
		var fi := Factions.ORDER.find(String(c.get("faction", ""))) if g in ["gold", "lands"] else 0
		var fi2 := Factions.ORDER.find(String(c.get("faction2", ""))) if g in ["gold", "lands"] else 0
		_sort_cache[id] = [GROUPS.find(g), RARITY_ORDER.find(String(c.get("rarity", ""))), fi, fi2,
			int(c.get("mana_value", 0)), lname.to_lower()]
	all_ids.sort_custom(func(a, b): return _sort_cache[a] < _sort_cache[b])


func _passes(c: Dictionary) -> bool:
	if f_group != "all":
		var g := group_of(c)
		# a faith also shows its gold cards (after its own)
		var ok: bool = g == f_group or (g == "gold" and (c.get("faction") == f_group or c.get("faction2") == f_group))
		if not ok:
			return false
	if f_type > 0 and CardView.kind(c) != TYPES[f_type].to_lower():
		return false
	if f_rarity > 0 and c.get("rarity", "") != RARITIES[f_rarity].to_lower():
		return false
	if f_text != "":
		var hay := ""
		for fld in ["name", "subtype", "text"]:
			var s := String(c.get(fld, ""))
			hay += s + "\n" + I18n.t(s) + "\n"
		for ab in c.get("abilities", []):
			var s2 := String(ab.get("text", ""))
			hay += s2 + "\n" + I18n.t(s2) + "\n"
		if not hay.to_lower().contains(f_text):
			return false
	return true


func _clear_filters() -> void:
	f_group = "all"
	group_btns["all"].set_pressed_no_signal(true)
	for g in group_btns:
		if g != "all":
			group_btns[g].set_pressed_no_signal(false)
	f_type = 0
	f_rarity = 0
	type_opt.select(0)
	rarity_opt.select(0)
	search.text = ""
	f_text = ""
	_refilter()


func _fit_columns() -> void:
	if grid == null:
		return
	var w := scroll.size.x
	if w < 10.0:                            # before the first layout: the screen less the margins
		w = get_viewport_rect().size.x - 44.0
	w -= 18.0                               # room for the scroll bar
	var cw := CardView.BASE.x * scale_k
	grid.columns = maxi(1, int((w + GAP) / (cw + GAP)))


## Apply the filters: hide what fails, then show and order what passes, making missing
## thumbnails a batch per frame.
func _refilter() -> void:
	_gen += 1
	var gen := _gen
	shown = all_ids.filter(func(id): return _passes(CardDB.get_card(id)))
	count_label.text = I18n.t("Showing %d of %d cards") % [shown.size(), all_ids.size()]
	var keep := {}
	for id in shown:
		keep[id] = true
	for id in views:
		if not keep.has(id):
			views[id].visible = false
	scroll.scroll_vertical = 0
	drag.stop()
	var t0 := Time.get_ticks_msec()
	for i in shown.size():
		var id: String = shown[i]
		var cv: CardView = views.get(id)
		if cv == null:
			_request_art(i)
			# wait for the picture (loaded on a thread) or for the next frame when this one is full
			while not _art_ready(id) or Time.get_ticks_msec() - t0 > FRAME_MS:
				await get_tree().process_frame
				if gen != _gen or not is_inside_tree():
					return
				t0 = Time.get_ticks_msec()
			cv = _make(id)
		cv.visible = true
		grid.move_child(cv, i)


## Start loading the pictures of the next cards to be made, off the main thread.
func _request_art(from: int) -> void:
	for j in range(from, mini(from + AHEAD, shown.size())):
		var path := _art_path(shown[j])
		if path == "" or _requested.has(path) or CardView._art_cache.has(path):
			continue
		_requested[path] = true
		if not ResourceLoader.exists(path) or ResourceLoader.load_threaded_request(path) != OK:
			CardView._art_cache[path] = null


## True once a card's picture is in CardView's cache (or it has none, or it failed).
func _art_ready(id: String) -> bool:
	var path := _art_path(id)
	if path == "" or CardView._art_cache.has(path):
		return true
	if not _requested.has(path):
		return false
	match ResourceLoader.load_threaded_get_status(path):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return false
		ResourceLoader.THREAD_LOAD_LOADED:
			CardView._art_cache[path] = ResourceLoader.load_threaded_get(path)
		_:
			CardView._art_cache[path] = null
	return true


func _art_path(id: String) -> String:
	return String(CardDB.get_card(id).get("art", ""))


func _make(id: String) -> CardView:
	var cv := CardView.create(id, scale_k)
	cv.tapped.connect(func(_v):
		if not drag.dragged:
			open_card(id))
	cv.long_pressed.connect(func(_v):
		if not drag.dragged:
			open_card(id))
	views[id] = cv
	grid.add_child(cv)
	return cv


## Read a card and leaf through the cards currently shown.
func open_card(id: String) -> CardViewer:
	return CardViewer.open(self, shown.duplicate(), maxi(0, shown.find(id)))


func _viewer_open() -> bool:
	for c in get_children():
		if c is CardViewer:
			return true
	return false


func _popup_open() -> bool:
	return rarity_opt.get_popup().visible or type_opt.get_popup().visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_visible_in_tree():
		if _viewer_open():
			return
		get_viewport().set_input_as_handled()
		_back()


func _back() -> void:
	closed.emit()
	queue_free()
