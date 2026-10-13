extends RefCounted
## The Basic lands pop-up of the deck builder (1.81), the same on every deck-building screen:
## your decks, Quick Duel, and the draft and sealed tournaments.
##  • One counter per faith's basic land, with "-" and "+", and how many of that faith's mana
##    symbols the deck's spells carry.
##  • Auto calculate asks how many cards the deck should have, then fills the rest with basic
##    lands shared by the mana symbols of the spells (DeckTools.basics_by_pips): 18 green and 12
##    red symbols with 17 lands to add make 10 Sacred Groves and 7 Feast Halls.
##  • Clear takes every basic land out. Nothing changes in the deck until Done (Undo takes the
##    whole change back); Cancel leaves the deck as it was.

const MAX_CARDS := 250


## Open it over `parent` for `deck`. on_done(counts: {faith: n}) gets the new basic lands.
static func open(parent: Control, deck: Dictionary, on_done: Callable) -> Control:
	var counts := {}
	for f in Factions.ORDER:
		counts[f] = int(deck.get(Factions.land_id(f), 0))
	var pips := DeckTools.deck_pips(deck)
	var others := DeckTools.count_without_basics(deck)
	var overlay := UIKit._modal(parent)
	overlay.name = "BasicLandsPopup"
	var v: VBoxContainer = overlay.get_meta("body")
	var w := UIKit._modal_width(parent)
	v.add_child(UIKit.title(I18n.t("Basic lands"), UIKit.FS_HEADING))
	var summary := UIKit.label("", UIKit.FS_SECONDARY, UIKit.TEXT, true)
	summary.name = "Summary"
	summary.custom_minimum_size.x = w
	v.add_child(summary)
	var grid := GridContainer.new()
	grid.name = "Lands"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UIKit.SP_3)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var count_labels := {}
	var refresh := func():
		var basics := 0
		for f in counts:
			basics += int(counts[f])
			(count_labels[f] as Label).text = str(counts[f])
		summary.text = I18n.t("Other cards: %d · Basic lands: %d · Deck: %d cards") % [others, basics, others + basics]
	for f in Factions.ORDER:
		var ff: String = f
		var cell := VBoxContainer.new()
		cell.name = "Land_" + f
		cell.custom_minimum_size.x = (w - 2 * UIKit.SP_3) / 3.0
		cell.add_theme_constant_override("separation", 0)
		grid.add_child(cell)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 6)
		cell.add_child(head)
		var sig := _Sigil.new()
		sig.faith = f
		sig.custom_minimum_size = Vector2(28, 28)
		head.add_child(sig)
		var sym := ""
		for k in Factions.MANA_TO_FACTION:
			if Factions.MANA_TO_FACTION[k] == f:
				sym = k
		var nm := UIKit.label(I18n.t(Factions.info(f)["land_name"]), UIKit.FS_SECONDARY, UIKit.faction_ink(f))
		nm.clip_text = true
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(nm)
		var np := int(pips.get(sym, 0))
		var pl := UIKit.label(I18n.t("%d symbols") % np if np > 0 else " ", UIKit.FS_MIN, UIKit.DIM)
		pl.name = "Symbols"
		cell.add_child(pl)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		cell.add_child(row)
		var minus := UIKit.button("-", func():
			counts[ff] = maxi(0, int(counts[ff]) - 1)
			refresh.call(), 52)
		minus.name = "Minus"
		minus.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
		row.add_child(minus)
		var n := UIKit.label("0", UIKit.FS_HEADING, UIKit.TEXT)
		n.name = "Count"
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(n)
		count_labels[f] = n
		var plus := UIKit.button("+", func():
			counts[ff] = mini(MAX_CARDS, int(counts[ff]) + 1)
			refresh.call(), 52)
		plus.name = "Plus"
		plus.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
		row.add_child(plus)
	var warn := UIKit.label("", UIKit.FS_SECONDARY, UIKit.RED, true)
	warn.name = "Warn"
	warn.custom_minimum_size.x = w
	v.add_child(warn)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 8)
	v.add_child(brow)
	var apply_auto := func(total: int):
		var lands := total - others
		if lands < 0:
			warn.text = I18n.t("The deck already has %d cards besides its basic lands: more than %d.") % [others, total]
			return
		warn.text = ""
		var got := DeckTools.basics_by_pips(deck, lands)
		for f in counts:
			counts[f] = int(got.get(f, 0))
		refresh.call()
	var auto := UIKit.button("Auto calculate", func():
		var basics := 0
		for f in counts:
			basics += int(counts[f])
		var start := 60 if others + basics > 40 or others > 30 else 40
		ask_size(parent, start, apply_auto), 120)
	auto.name = "Auto"
	auto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brow.add_child(auto)
	var clear := UIKit.button("Clear", func():
		for f in counts:
			counts[f] = 0
		warn.text = ""
		refresh.call(), 90)
	clear.name = "Clear"
	clear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brow.add_child(clear)
	var orow := brow
	var cancel := UIKit.button("Cancel", overlay.queue_free, 90)
	cancel.name = "Cancel"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orow.add_child(cancel)
	var done := UIKit.primary_button("Done", func():
		overlay.queue_free()
		on_done.call(counts.duplicate()), 100)
	done.name = "Ok"
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orow.add_child(done)
	refresh.call()
	return overlay


## "How many cards should the deck have?": a number with "-" and "+" (and 40 and 60 at a tap),
## then Calculate calls on_ok(n).
static func ask_size(parent: Control, start: int, on_ok: Callable) -> Control:
	var overlay := UIKit._modal(parent)
	overlay.name = "DeckSizePopup"
	var v: VBoxContainer = overlay.get_meta("body")
	var w := UIKit._modal_width(parent)
	v.add_child(UIKit.title(I18n.t("Auto calculate"), UIKit.FS_HEADING))
	var info := UIKit.label(I18n.t("How many cards should the deck have? Basic lands fill the rest, shared by the mana symbols of your spells. The least is 40."), UIKit.FS_SECONDARY, UIKit.TEXT, true)
	info.custom_minimum_size.x = w
	v.add_child(info)
	var size := [clampi(start, 1, MAX_CARDS)]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var n := UIKit.label("", UIKit.FS_HEADING, UIKit.TEXT)
	n.name = "Size"
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var show := func():
		n.text = str(size[0])
	var step := func(d: int):
		size[0] = clampi(size[0] + d, 1, MAX_CARDS)
		show.call()
	for d in [-10, -1]:
		var dd: int = d
		var b := UIKit.button(str(d), func(): step.call(dd), UIKit.TARGET_W)
		b.name = "Step%d" % d
		row.add_child(b)
	row.add_child(n)
	for d in [1, 10]:
		var dd: int = d
		var b := UIKit.button("+" + str(d), func(): step.call(dd), UIKit.TARGET_W)
		b.name = "Step+%d" % d
		row.add_child(b)
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 8)
	v.add_child(prow)
	for p in [40, 60]:
		var pp: int = p
		var b := UIKit.button(I18n.t("%d cards") % p, func():
			size[0] = pp
			show.call(), 120)
		b.name = "Preset%d" % p
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prow.add_child(b)
	var orow := HBoxContainer.new()
	orow.add_theme_constant_override("separation", 8)
	v.add_child(orow)
	var cancel := UIKit.button("Cancel", overlay.queue_free, 120)
	cancel.name = "Cancel"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orow.add_child(cancel)
	var ok := UIKit.primary_button("Calculate", func():
		overlay.queue_free()
		on_ok.call(size[0]), 120)
	ok.name = "Ok"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orow.add_child(ok)
	show.call()
	return overlay


## A faith's sigil, drawn small.
class _Sigil extends Control:
	var faith := ""

	func _draw() -> void:
		UIKit.draw_sigil(self, faith, size * 0.5, minf(size.x, size.y) * 0.4, UIKit.faction_ink(faith), 2.0)
