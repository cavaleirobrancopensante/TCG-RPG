class_name TournamentScreen
extends Control
## The bracket of a city's draft tournament: who plays whom, results so far, and the
## button to play your next match (or collect your prize).

signal play_match(opponent: int)
signal edit_deck
signal done

var draft: Draft


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	var v := VBoxContainer.new()
	UIKit.content_rect(v)
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)
	var t := UIKit.title(I18n.t("Tournament of %s") % GameState.city(draft.city).get("name", ""), 38)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var opp := draft.player_opponent()
	if opp >= 0:
		head.add_child(UIKit.button("Deck", func(): edit_deck.emit(), 130))
		head.add_child(UIKit.button(I18n.t("Play %s") % draft.names[opp], func(): play_match.emit(opp), 300))
	else:
		head.add_child(UIKit.button("Collect prize", func(): done.emit(), 240))
	var stage_names := ["Quarter-finals", "Semi-finals", "Final", "Finished"]
	v.add_child(UIKit.label(I18n.t(stage_names[draft.stage]) + "   ·   " + _status(), 20, UIKit.TEXT, true))
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
				var r := Rect2(ri * col_w + 10, y - 18, col_w - 30, 36)
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
				UIKit.draw_sigil(self, f, r.position + Vector2(18, 18), 11, UIKit.faction_ink(f), 1.6)
				draw_string(bold if seat == 0 else font, r.position + Vector2(34, 24), draft.names[seat], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 40, 17, Tapestry.INK if not lost else Color(Tapestry.INK, 0.5))
				if ri + 1 < cols:
					var nx := (ri + 1) * col_w + 10
					var ny := size.y / maxf(1.0, list.size() / 2.0) * (k / 2 + 0.5)
					draw_line(Vector2(r.end.x, y), Vector2(r.end.x + 10, y), Tapestry.INK, 1.4)
					draw_line(Vector2(r.end.x + 10, y), Vector2(r.end.x + 10, ny), Tapestry.INK, 1.4)
					draw_line(Vector2(r.end.x + 10, ny), Vector2(nx, ny), Tapestry.INK, 1.4)
