class_name TournamentScreen
extends Control
## The bracket of a city's draft tournament: who plays whom, results so far, and the
## button to play your next match (or collect your prize). With more than one list built from
## the draft pool, the chooser beside the status line picks the one played next.

signal play_match(opponent: int)
signal edit_deck
signal deck_chosen(deck_index: int)     # a GameState.decks index, one of `lists`
signal done

var draft: Draft
var lists: Array = []           # GameState.decks indices of the lists built from the draft pool
var chosen := -1                # the list played in the next match
var pool := {}                  # the draft pool, to mark lists that are not legal yet
var deck_pick: OptionButton


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	var compact := get_viewport_rect().size.y < 600.0
	var v := VBoxContainer.new()
	UIKit.content_rect(v)
	v.add_theme_constant_override("separation", UIKit.SP_1 if compact else UIKit.GAP)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.GAP)
	v.add_child(head)
	head.add_child(UIKit.corner_space(22, UIKit.GAP))
	var t := UIKit.title(I18n.t("Tournament of %s") % GameState.city(draft.city).get("name", ""), UIKit.FS_HEADING + 2 if compact else UIKit.FS_TITLE - 2)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(t)
	var opp := draft.player_opponent()
	if opp >= 0:
		var deck := UIKit.button("Edit deck", func(): edit_deck.emit(), 160)
		deck.name = "Deck"
		deck.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(deck)
		var play := UIKit.primary_button(I18n.t("Play %s") % draft.names[opp], func(): play_match.emit(opp), 240)
		play.name = "PlayMatch"
		head.add_child(play)
	else:
		var prize := UIKit.primary_button("Collect prize", func(): done.emit(), 240)
		prize.name = "CollectPrize"
		head.add_child(prize)
	var stage_names := ["Quarter-finals", "Semi-finals", "Final", "Finished"]
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", UIKit.GAP)
	v.add_child(srow)
	var st := UIKit.label(I18n.t(stage_names[draft.stage]) + "   ·   " + _status(), UIKit.FS_BODY, UIKit.TEXT, true)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	st.max_lines_visible = 2
	srow.add_child(st)
	if opp >= 0 and not lists.is_empty():
		deck_pick = OptionButton.new()
		deck_pick.name = "ChooseDeck"
		deck_pick.tooltip_text = I18n.t("The deck you play in the next match")
		deck_pick.custom_minimum_size = Vector2(minf(300.0, get_viewport_rect().size.x * 0.32), UIKit.TARGET)
		deck_pick.clip_text = true
		deck_pick.add_theme_font_size_override("font_size", UIKit.FS_SECONDARY)
		for i in lists:
			var dk: Dictionary = GameState.decks[i]
			var ok := DeckTools.validate(dk["cards"], pool, DeckTools.DRAFT_COPIES) == ""
			deck_pick.add_item("%s  (%d)%s" % [I18n.t(dk["name"]), DeckTools.count(dk["cards"]), "" if ok else "  ✗"])
		deck_pick.select(maxi(0, lists.find(chosen)))
		deck_pick.item_selected.connect(func(k):
			chosen = int(lists[k])
			deck_chosen.emit(chosen))
		srow.add_child(deck_pick)
	var b := _Bracket.new()
	b.draft = draft
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(b)


func _status() -> String:
	if draft.stage >= 3:
		var ch := draft.champion()
		if ch == 0:
			return I18n.t("You are the champion!")
		return I18n.t("%s wins the tournament.") % draft.names[ch]
	if draft.player_out:
		return I18n.t("You are out. The rest of the bracket will be played to the end.")
	var opp := draft.player_opponent()
	return I18n.t("Next: you against %s (%s).") % [draft.names[opp], Factions.info(draft.main_faith(opp))["name"]]


class _Bracket extends Control:
	var draft: Draft

	func _draw() -> void:
		var font := Tapestry.font("book")
		var bold := Tapestry.font("bold")
		var cols := 4
		var col_w := size.x / cols
		# rebuild the rounds from the results: round 0 starts from the original seating
		var rounds: Array = []
		var first: Array = []
		if not draft.results.is_empty():
			for pr in draft.results[0]:
				first.append(pr)
		var entrants: Array = []
		if draft.results.is_empty():
			entrants = draft.bracket.duplicate()
		else:
			for pr in draft.results[0]:
				entrants.append_array([pr[0], pr[1]])
		rounds.append(entrants)
		for r in draft.results:
			var winners: Array = []
			for pr in r:
				winners.append(pr[0])
			rounds.append(winners)
		if draft.results.size() < 3 and draft.results.size() > 0:
			pass
		for ri in rounds.size():
			var list: Array = rounds[ri]
			var slot_h := size.y / maxf(1.0, list.size())
			for k in list.size():
				var seat: int = list[k]
				var y := slot_h * (k + 0.5)
				var bh := clampf(slot_h - 6.0, 30.0, 44.0)
				var r := Rect2(ri * col_w + 10, y - bh * 0.5, col_w - 30, bh)
				var lost := false
				if ri < draft.results.size():
					for pr in draft.results[ri]:
						if pr[1] == seat:
							lost = true
				var fill := Tapestry.PARCHMENT_LIGHT if not lost else Tapestry.PARCHMENT_DARK
				if seat == 0:
					fill = Tapestry.GILT if not lost else Color(Tapestry.GILT, 0.5)
				Tapestry.ink_rect(self, r, fill, 1.6)
				var f := draft.main_faith(seat)
				UIKit.draw_sigil(self, f, r.position + Vector2(18, bh * 0.5), 11, UIKit.faction_ink(f), 1.6)
				var fs := UIKit.FS_SECONDARY
				draw_string(bold if seat == 0 else font, r.position + Vector2(34, bh * 0.5 + fs * 0.36), draft.names[seat], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 40, fs, Tapestry.INK if not lost else Color(Tapestry.INK, 0.5))
				if ri + 1 < cols:
					var nx := (ri + 1) * col_w + 10
					var ny := size.y / maxf(1.0, list.size() / 2.0) * (k / 2 + 0.5)
					draw_line(Vector2(r.end.x, y), Vector2(r.end.x + 10, y), Tapestry.INK, 1.4)
					draw_line(Vector2(r.end.x + 10, y), Vector2(r.end.x + 10, ny), Tapestry.INK, 1.4)
					draw_line(Vector2(r.end.x + 10, ny), Vector2(nx, ny), Tapestry.INK, 1.4)
