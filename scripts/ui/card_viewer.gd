class_name CardViewer
extends Control
## Read a card up close and leaf through its neighbours: ‹ › arrows, swiping, or the
## keyboard arrows. Shows keyword explanations and context actions (Play, Buy, Sell…).
##
##   CardViewer.open(parent, entries, index, actions)
##     entries: Array of ids, or of {"id": String, "foil": bool, "data": Dictionary (tokens)}
##     actions: Callable(entry: Dictionary, index: int) -> Array of
##              [label: String, callback: Callable, enabled: bool, closes: bool, why_not: String]
##              (why_not, optional: shown under the buttons while the action is disabled)
##   close_label: the dismiss button's text ("Close", or "Cancel" for the duel's hand preview).
##   The "?" button opens the rules glossary (card types, keywords, the stack).

signal closed

const KEYWORDS := {
	"flying": "Flying: can only be blocked by creatures with flying or reach.",
	"reach": "Reach: can block creatures with flying.",
	"haste": "Haste: can attack and use Tap abilities the turn it enters.",
	"lifelink": "Lifelink: damage it deals also heals you.",
	"deathtouch": "Deathtouch: any damage it deals to a creature is lethal.",
	"vigilance": "Vigilance: does not tap when it attacks.",
	"trample": "Trample: damage beyond what kills its blocker hits the player.",
	"defender": "Defender: cannot attack.",
	"martyr": "Martyr: when this creature dies, put a +1/+1 counter on another target creature you control.",
	"sanctified": "Sanctified: Pact cards can't target it, Pact creatures can't block it, and damage from the Pact is prevented.",
	"dread": "Dread: can only be blocked by Pact creatures and Constructs.",
	"regenerate": "Regenerate: pay its cost to shield it; the next time it would be destroyed this turn, it is tapped, healed and taken out of combat instead.",
	"first_strike": "First strike: deals combat damage before creatures without it.",
	"unmoved": "Unmoved: enemy spells and abilities can't tap it, return it to its owner's hand or shrink it.",
	"converted": "Converted: it can't attack or block.",
	"immortal": "Immortal: if it would be put into a graveyard from anywhere, it is exiled instead. Angels return to Heaven, demons are cast back into Hell; no necromancy can raise them.",
}
## Mechanics named in rules text, explained under the card.
const MECHANICS := {
	"Grace": "Grace: you have more life than you started the duel with.",
	"Bloodied": "Bloodied: you have 5 or less life.",
	"Rooted": "Rooted: you control six or more lands.",
	"Carouse": "Carouse: you already played another card this turn.",
	"Composure": "Composure: you hold four or more cards.",
	"Idle": "Idle: at the end of your turn, if this creature is untapped and didn't attack this turn.",
	"Overclock": "Overclock: you may pay more as you play it for the bonus.",
	"Assembly": "Assembly: this creature gets +1/+1 for each other Construct you control.",
	"Upkeep": "Upkeep N: at the start of your turn pay N, or it is sacrificed.",
	"Foresight": "Foresight N: look at the top N cards, choose which stay on top and which go to the bottom.",
	"Freeze": "Freeze: tap it; it doesn't untap next turn.",
	"Pacif": "Pacify: it can't attack for the rest of the duel.",
	"Snare": "Snare: it can't attack or block while this relic stays.",
	"fights": "Fight: a creature you control and the target deal damage equal to their power to each other.",
	"rummage": "Rummage: draw a card, then discard a card.",
	"Rummage": "Rummage: draw a card, then discard a card.",
	"Unearth": "Unearth: from your graveyard, pay its cost: it returns with haste, and is exiled at end of turn or if it would leave.",
	"Counter target": "Counter: the spell is cancelled and goes to its owner's graveyard. Cast it while the enemy spell is on the stack.",
	"Charge": "Charge: when it attacks, for each other attacking Knight choose one (trample, first strike, vigilance, lifelink, +1/+0); all your Knights gain them until end of turn.",
	"Legendary": "Legendary: you may have only one with this name on the battlefield at a time.",
	"Two-faced": "Two-faced: Peace and Crusade. Peace begins when the first two-faced card appears. At the start of each turn: at Peace, if the player whose turn ended cast two or more spells in it, Crusade begins; at Crusade, if he cast none, Peace returns. Every two-faced card turns over with it. Tap the card to read its other face.",
	"Possess": "Possess: when the possessed creature dies, the demon moves to another creature its master controls; if there is none, it is exiled.",
	"Heretic": "Heretic: one who knew the faith and turned from it (the Pact's cultists). Inquisitors judge Heretics.",
	"Pagan": "Pagan: one who never received the faith (the other faiths' people). The Church's answer is the mission: conversion.",
	"Demon": "Demon: everything fantastical that is not an angel. Exorcisms destroy Demons; a possession destroyed frees its host.",
}
const SWIPE := 70.0

var entries: Array = []
var index := 0
var actions: Callable
var close_label := "Close"
var card_view: CardView
var info_box: VBoxContainer
var head_box: HBoxContainer       # the name and the "?" button, always in view
var info_scroll: ScrollContainer   # the card's text, scrolling when it is taller than the screen
var actions_box: VBoxContainer     # the action buttons, always in view under the text
var left_btn: Button
var right_btn: Button
var _press_pos := Vector2.ZERO
var _pressing := false
var _card_scale := 2.0
var _home := Vector2.ZERO
var _swiping := false
var _slide: Tween
var _info_dirty := false
var _plate_top := 0.0
# zoom: pinch with two fingers, the mouse wheel, or a trackpad pinch
const ZOOM_MAX := 4.0
var _zoom := 1.0
var _touches := {}               # finger index -> position
var _pinch_d0 := 0.0
var _pinch_z0 := 1.0
var _pinch_mid := Vector2.ZERO
var _pinching := false
var _flipped := {}               # entry index -> true: a two-faced card shows its other face


static func open(parent: Node, p_entries: Array, p_index: int, p_actions: Callable = Callable(), p_close_label: String = "Close") -> CardViewer:
	var v := CardViewer.new()
	v.close_label = p_close_label
	for e in p_entries:
		v.entries.append(e if typeof(e) == TYPE_DICTIONARY else {"id": e, "foil": false})
	v.index = clampi(p_index, 0, maxi(0, p_entries.size() - 1))
	v.actions = p_actions
	parent.add_child(v)
	return v


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(dim)
	add_child(dim)

	var vp := get_viewport_rect().size
	_card_scale = clampf((vp.y - UIKit.TOP - 40) / CardView.BASE.y, 1.2, 2.3)
	card_view = CardView.new()
	card_view.scale_factor = _card_scale
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_view)

	var plate := PanelContainer.new()
	plate.name = "Plate"
	plate.clip_contents = true
	add_child(plate)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UIKit.GAP)
	col.custom_minimum_size.x = 340
	plate.add_child(col)
	head_box = HBoxContainer.new()
	head_box.add_theme_constant_override("separation", 8)
	col.add_child(head_box)
	info_scroll = ScrollContainer.new()
	info_scroll.name = "InfoScroll"
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(info_scroll)
	info_box = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 6)
	info_scroll.add_child(info_box)
	actions_box = VBoxContainer.new()
	actions_box.add_theme_constant_override("separation", 6)
	col.add_child(actions_box)
	# wrapped text settles its height a frame after it gets its width: fit the plate again then
	info_box.minimum_size_changed.connect(func(): _fit_plate.call_deferred())
	actions_box.minimum_size_changed.connect(func(): _fit_plate.call_deferred())
	head_box.minimum_size_changed.connect(func(): _fit_plate.call_deferred())
	# arrows last, so nothing can ever cover them
	left_btn = _arrow("‹", prev)
	right_btn = _arrow("›", next)
	_layout()
	_show(0)


func _arrow(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(72, 120)
	b.add_theme_font_size_override("font_size", 56)
	b.pressed.connect(cb)
	add_child(b)
	return b


## Arrows sit at the screen edges; the card and its text plate share the space between.
func _layout() -> void:
	var vp := get_viewport_rect().size
	var plate: Control = get_node("Plate")
	var lane := Vector2(8 + 72 + 12, vp.x - 8 - 72 - 12)     # x range between the arrows
	var plate_w := 380.0
	var cs := CardView.BASE * _card_scale
	if cs.x + 20 + plate_w > lane.y - lane.x:
		_card_scale = maxf(0.8, (lane.y - lane.x - 20 - plate_w) / CardView.BASE.x)
		card_view.scale_factor = _card_scale
		cs = CardView.BASE * _card_scale
	var total := cs.x + 20 + plate_w
	var x0 := lane.x + maxf(0.0, (lane.y - lane.x - total) * 0.5)
	var top := UIKit.TOP + (vp.y - UIKit.TOP - cs.y) * 0.5
	card_view.position = Vector2(x0, top)
	_home = card_view.position
	plate.position = Vector2(x0 + cs.x + 20, top)
	_plate_top = top
	plate.custom_minimum_size = Vector2(plate_w, 0)
	plate.size = Vector2(minf(plate_w, lane.y - plate.position.x), plate.size.y)
	left_btn.position = Vector2(8, vp.y * 0.5 - 60 + UIKit.TOP * 0.5)
	right_btn.position = Vector2(vp.x - 8 - 72, vp.y * 0.5 - 60 + UIKit.TOP * 0.5)


func entry() -> Dictionary:
	return entries[index] if index < entries.size() else {}


## The id on show: a two-faced card turned over shows its other face.
func _shown_id(e: Dictionary) -> String:
	var id := String(e.get("id", ""))
	if _flipped.get(index, false):
		var c := CardDB.get_card(id)
		if c.has("transform"):
			return String(c["transform"])
	return id


static func is_two_faced(id: String) -> bool:
	return CardDB.get_card(id).has("transform")


## Turn a two-faced card over (the button, or a tap on the card).
func flip() -> void:
	var e := entry()
	if e.is_empty() or e.has("data") or not is_two_faced(String(e["id"])):
		return
	_flipped[index] = not _flipped.get(index, false)
	card_view.set_card(_shown_id(e), e.get("foil", false), {})
	var tw := create_tween()
	card_view.pivot_offset = card_view.size * 0.5
	card_view.scale = Vector2(0.1, 1.0)
	tw.tween_property(card_view, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	refresh()


func next() -> void:
	if index < entries.size() - 1:
		index += 1
		_show(1)


func prev() -> void:
	if index > 0:
		index -= 1
		_show(-1)


func close() -> void:
	closed.emit()
	queue_free()


## Rebuild the details for the current card. dir: -1/1 slides the card in from that side.
func _show(dir: int) -> void:
	var e := entry()
	if e.is_empty():
		return
	card_view.set_card(_shown_id(e), e.get("foil", false), e.get("data", {}))
	_set_zoom(1.0, Vector2.ZERO)
	if dir != 0:
		var home := _home
		if _slide != null and _slide.is_valid():
			_slide.kill()
		card_view.position = home + Vector2(60 * dir, 0)
		card_view.modulate.a = 0.3
		_slide = create_tween().set_parallel(true)
		_slide.tween_property(card_view, "position", home, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_slide.tween_property(card_view, "modulate:a", 1.0, 0.16)
	left_btn.disabled = index <= 0
	right_btn.disabled = index >= entries.size() - 1
	# the text plate is rebuilt once per frame at most, however fast the cards are flipped
	if not _info_dirty:
		_info_dirty = true
		_flush_info.call_deferred()


func _flush_info() -> void:
	_info_dirty = false
	if is_inside_tree() and not is_queued_for_deletion():
		_fill_info(entry())


func refresh() -> void:
	_fill_info(entry())


func _fill_info(e: Dictionary) -> void:
	UIKit.clear(info_box)
	UIKit.clear(actions_box)
	UIKit.clear(head_box)
	var c: Dictionary = e.get("data", {}) if e.has("data") else CardDB.get_card(_shown_id(e))
	var f: String = c.get("faction", "machine")
	var head := head_box
	var tl := UIKit.title(I18n.t(c.get("name", "")), UIKit.FS_HEADING + 2)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size.x = 240
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	var help := UIKit.button("?", open_glossary, UIKit.TARGET_W)
	help.name = "GlossaryButton"
	help.custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
	help.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
	help.tooltip_text = I18n.t("Rules glossary")
	help.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if c.has("transform") and not e.has("data"):
		var fb := UIKit.button("⟳", flip, UIKit.TARGET_W)
		fb.name = "FlipButton"
		fb.custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
		fb.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
		fb.tooltip_text = I18n.t("Turn the card over to read its other face")
		fb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		head.add_child(fb)
	head.add_child(help)
	var line := "%s · %s" % [Factions.info(f)["name"], I18n.t(String(c.get("rarity", "")).capitalize())]
	if e.get("foil", false):
		line += " · " + I18n.t("Foil")
	info_box.add_child(UIKit.label(line, UIKit.FS_SECONDARY + 1, UIKit.faction_ink(f), true))
	# type line, cost (as pips) and power/toughness
	var type_line := CardView.type_line(c)
	if c.get("type") != "land" and c.get("rarity") != "token":
		type_line += "   ·   " + I18n.t("Cost %s") % CardView.cost_tokens(c.get("cost", {}))
	if c.get("type") == "creature":
		type_line += "   ·   %d/%d" % [c.get("power", 0), c.get("toughness", 0)]
	var tline := CardView.RulesText.new(type_line, UIKit.FS_SECONDARY, UIKit.TEXT)
	tline.name = "TypeLine"
	tline.custom_minimum_size.x = 300
	info_box.add_child(tline)
	var shown_text := CardView.display_text(c)
	if shown_text != "":
		var rules := CardView.RulesText.new(shown_text, UIKit.FS_BODY, UIKit.TEXT)
		rules.name = "RulesText"
		rules.custom_minimum_size.x = 300
		info_box.add_child(rules)
	elif String(c.get("flavor", "")) != "":
		# a vanilla creature: its flavour stands in for the rules text
		var fl := UIKit.label(I18n.t(c["flavor"]), UIKit.FS_BODY - 1, UIKit.DIM, true)
		fl.name = "Flavor"
		fl.custom_minimum_size.x = 300
		fl.add_theme_font_override("font", Tapestry.font("italic"))
		info_box.add_child(fl)
	# on the battlefield: what is on it (a possession, equipment) and its stats now
	for note in e.get("notes", []):
		var nl := CardView.RulesText.new(String(note), UIKit.FS_BODY - 1, UIKit.GOLD)
		nl.name = "BoardNote"
		nl.custom_minimum_size.x = 300
		info_box.add_child(nl)
	for kw in c.get("keywords", []):
		if KEYWORDS.has(kw):
			info_box.add_child(UIKit.label(I18n.t(KEYWORDS[kw]), UIKit.FS_SECONDARY, UIKit.DIM, true))
	var shown := {}
	for word in MECHANICS:
		var line2: String = MECHANICS[word]
		var has_word: bool = String(c.get("text", "")).contains(word) or (word == "Legendary" and c.get("legendary", false))
		if has_word and not shown.has(line2):
			shown[line2] = true
			info_box.add_child(UIKit.label(I18n.t(line2), UIKit.FS_SECONDARY, UIKit.DIM, true))
	if c.has("transform"):
		var face := I18n.t("Crusade face") if c.has("front") else I18n.t("Peace face")
		info_box.add_child(UIKit.label(face + ". " + I18n.t("Tap the card or ⟳ to read the other face."), UIKit.FS_SECONDARY, UIKit.GOLD, true))
	if c.get("rarity") != "token" and c.get("type") != "land" and not c.get("proto", false):
		info_box.add_child(UIKit.label(I18n.t("You own %d") % GameState.owned_count(e["id"]), UIKit.FS_SECONDARY, UIKit.DIM))
	info_box.add_child(UIKit.label("%d / %d" % [index + 1, entries.size()], UIKit.FS_SECONDARY, UIKit.DIM))
	var row := HFlowContainer.new()
	row.name = "Actions"
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 8)
	var reasons: Array = []
	if actions.is_valid():
		for a in actions.call(e, index):
			var cb: Callable = a[1]
			var closes: bool = a[3] if a.size() > 3 else false
			var b := UIKit.button(a[0], func():
				cb.call()
				if closes:
					close()
				elif is_instance_valid(self):
					refresh.call_deferred(), 150)
			b.disabled = not a[2]
			b.add_theme_font_size_override("font_size", UIKit.FS_BODY)
			row.add_child(b)
			if b.disabled and a.size() > 4 and String(a[4]) != "":
				reasons.append(String(a[4]))
	var cl := UIKit.button(close_label, close, 120)
	cl.name = "CloseButton"
	row.add_child(cl)
	actions_box.add_child(row)
	for why in reasons:
		var wl := UIKit.label(why, UIKit.FS_SECONDARY, UIKit.RED, true)
		wl.name = "WhyNot"
		wl.custom_minimum_size.x = 300
		actions_box.add_child(wl)
	_fit_plate.call_deferred()


## The text plate is as tall as its text, up to the bottom of the screen; beyond that the text
## scrolls and the actions stay in view below it.
func _fit_plate() -> void:
	if not is_inside_tree():
		return
	var plate: Control = get_node("Plate")
	var vp := get_viewport_rect().size
	plate.position.y = _plate_top
	var room := vp.y - plate.position.y - 10.0
	var sb := plate.get_theme_stylebox("panel")
	var chrome := (sb.get_minimum_size().y if sb else 24.0) + UIKit.GAP
	var want := info_box.get_combined_minimum_size().y
	var h := minf(want, room - chrome - UIKit.GAP - head_box.get_combined_minimum_size().y - actions_box.get_combined_minimum_size().y)
	info_scroll.custom_minimum_size.y = maxf(80.0, h)
	plate.size.y = 0
	plate.reset_size()
	# a plate taller than the space below the card's top rises until it fits
	var over := plate.position.y + plate.size.y - (vp.y - 6.0)
	if over > 0:
		plate.position.y = maxf(UIKit.TOP + 4.0, plate.position.y - over)


## The rules glossary over the viewer: card types, keywords, conditions, the stack.
func open_glossary() -> RulesGlossary:
	var g := RulesGlossary.new()
	add_child(g)
	return g


func _glossary_open() -> bool:
	for ch in get_children():
		if ch is RulesGlossary:
			return true
	return false


# ------------------------------------------------------------------ swipe & keys

## Swipes are read anywhere on the screen (over the card, the text or the background),
## and the card follows the finger while dragging.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _is_top() or _glossary_open():
		return
	if _zoom_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_swiping = false
			_press_pos = event.position
		elif _pressing:
			_pressing = false
			var d: Vector2 = event.position - _press_pos
			if _swiping:
				card_view.position = _home
				card_view.modulate.a = 1.0
				get_viewport().set_input_as_handled()    # a swipe is not a button press
				if d.x > SWIPE and index > 0:
					prev()
				elif d.x < -SWIPE and index < entries.size() - 1:
					next()
			elif d.length() < 14.0 and _zoom <= 1.01 and card_view.get_global_rect().has_point(event.position):
				flip()          # a tap on a two-faced card turns it over
	elif event is InputEventMouseMotion and _pressing and _zoom > 1.01:
		# zoomed in: the finger moves the picture around
		card_view.position += event.relative
		_clamp_pan()
	elif event is InputEventMouseMotion and _pressing:
		var d: Vector2 = event.position - _press_pos
		if not _swiping and absf(d.x) > 18.0 and absf(d.x) > absf(d.y) * 1.3:
			_swiping = true
		if _swiping:
			card_view.position = _home + Vector2(d.x * 0.5, 0)
			card_view.modulate.a = clampf(1.0 - absf(d.x) / 600.0, 0.5, 1.0)


## Zoom gestures. Returns true when the event was a zoom (so it is not a swipe or a tap).
func _zoom_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() == 2:
			var p: Array = _touches.values()
			_pinch_d0 = maxf(10.0, (p[0] as Vector2).distance_to(p[1]))
			_pinch_z0 = _zoom
			_pinch_mid = ((p[0] as Vector2) + (p[1] as Vector2)) * 0.5
			_pinching = true
			_pressing = false
			_swiping = false
			return true
		if _touches.size() < 2 and _pinching:
			_pinching = false
			_pressing = false
			return true
		return false
	if event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _pinching and _touches.size() >= 2:
			var p: Array = _touches.values()
			var d := (p[0] as Vector2).distance_to(p[1])
			var mid := ((p[0] as Vector2) + (p[1] as Vector2)) * 0.5
			card_view.position += mid - _pinch_mid      # two fingers also pan
			_pinch_mid = mid
			_set_zoom(_pinch_z0 * d / _pinch_d0, mid)
			return true
		return _pinching
	if event is InputEventMagnifyGesture:
		_set_zoom(_zoom * event.factor, event.position)
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_set_zoom(_zoom * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), event.position)
		return true
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT and _zoom > 1.01:
		_set_zoom(1.0, Vector2.ZERO)
		return true
	return _pinching


## Zoom the card about a screen point, keeping that point under the finger.
func _set_zoom(z: float, at: Vector2) -> void:
	z = clampf(z, 1.0, ZOOM_MAX)
	if z <= 1.001:
		_zoom = 1.0
		card_view.scale = Vector2.ONE
		card_view.position = _home
		return
	if _slide != null and _slide.is_valid():
		_slide.kill()
	card_view.modulate.a = 1.0
	var k := z / _zoom
	card_view.position = at - (at - card_view.position) * k
	_zoom = z
	card_view.scale = Vector2(z, z)
	_clamp_pan()


## Never let the zoomed card slide off the screen.
func _clamp_pan() -> void:
	var vp := get_viewport_rect().size
	var sz := card_view.size * _zoom
	var p := card_view.position
	p.x = clampf(p.x, minf(vp.x - sz.x, _home.x) - 40.0, maxf(0.0, _home.x) + 40.0)
	p.y = clampf(p.y, minf(vp.y - sz.y, _home.y) - 40.0, maxf(0.0, _home.y) + 40.0)
	card_view.position = p


func _is_top() -> bool:
	var p := get_parent()
	if p == null:
		return false
	for i in range(p.get_child_count() - 1, -1, -1):
		var ch := p.get_child(i)
		if ch is CardViewer:
			return ch == self
	return true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if _glossary_open():
		return
	if event.is_action_pressed("ui_right"):
		next()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		prev()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
