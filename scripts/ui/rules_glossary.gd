class_name RulesGlossary
extends Control
## A short rules glossary, opened from the card viewer's "?" button: the card types, the mana
## symbols, every keyword with its one-line meaning, the conditions and mechanics named in
## rules text, and the stack in one sentence. Close with the button, Escape or a tap outside.

const TYPES := [
	"Creature: a permanent that fights. It stays on the battlefield, blocks, and can attack from your next turn (at once with haste).",
	"Sorcery: cast it in your main phase while the stack is empty. It does what it says, then goes to the graveyard.",
	"Instant: cast it whenever you have priority, in either player's turn and in answer to a spell or ability. Then it goes to the graveyard.",
	"Relic: a permanent that stays on the battlefield and works for as long as it stays.",
	"Land: play at most one a turn, in your main phase. Tap your lands for the mana that pays for your cards.",
	"Token: a creature made by an effect, not a card. When it leaves the battlefield it is gone.",
]
const GENERIC := "{1} {2} {X}: generic mana, paid with mana of any kind."
const STACK := "The stack: cast cards and used abilities wait on the stack, and when both players pass, the last one added resolves first."
## Keyword order of the card spec.
const KEYWORD_ORDER := ["flying", "martyr", "lifelink", "sanctified", "deathtouch", "dread", "trample", "reach",
	"regenerate", "haste", "first_strike", "vigilance", "defender", "unmoved"]

var panel: PanelContainer
var list: VBoxContainer


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.7)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(dim)
	add_child(dim)

	var vp := get_viewport_rect().size
	var w := minf(920.0, vp.x - 40.0)
	var h := vp.y - UIKit.TOP - 24.0
	panel = PanelContainer.new()
	panel.name = "GlossaryPanel"
	panel.custom_minimum_size = Vector2(w, h)
	panel.size = Vector2(w, h)
	panel.position = Vector2((vp.x - w) * 0.5, UIKit.TOP + 12.0)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var t := UIKit.title("Rules glossary", UIKit.FS_HEADING + 4)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close_btn := UIKit.button("Close", close, 130)
	close_btn.name = "CloseButton"
	head.add_child(close_btn)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UIKit.SP_1)
	scroll.add_child(list)
	_fill(w - 70.0)


func _fill(text_w: float) -> void:
	_heading("Card types")
	for line in TYPES:
		_line(I18n.t(line), text_w)
	_heading("Mana")
	var parts: Array = []
	for m in Factions.MANA_ORDER:
		parts.append("{%s} %s" % [m, Factions.info(Factions.MANA_TO_FACTION[m])["name"]])
	_line(", ".join(parts), text_w)
	_line(I18n.t(GENERIC), text_w)
	_heading("Keywords")
	for kw in KEYWORD_ORDER:
		if CardViewer.KEYWORDS.has(kw):
			_line(I18n.t(CardViewer.KEYWORDS[kw]), text_w)
	_heading("Conditions and mechanics")
	var seen := {}
	for word in CardViewer.MECHANICS:
		var m: String = CardViewer.MECHANICS[word]
		if not seen.has(m):
			seen[m] = true
			_line(I18n.t(m), text_w)
	_heading("The stack")
	_line(I18n.t(STACK), text_w)


func _heading(t: String) -> void:
	var l := UIKit.title(t, UIKit.FS_HEADING - 4)
	list.add_child(l)


func _line(t: String, w: float) -> CardView.RulesText:
	var r := CardView.RulesText.new(t, UIKit.FS_BODY, UIKit.TEXT)
	r.custom_minimum_size.x = w
	list.add_child(r)
	return r


func close() -> void:
	queue_free()


func _gui_input(event: InputEvent) -> void:
	# a tap on the dimmed space around the panel closes the glossary
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if not event.pressed and not panel.get_global_rect().has_point(event.global_position):
			close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_visible_in_tree():
		get_viewport().set_input_as_handled()
		close()
