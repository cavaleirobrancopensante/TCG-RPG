class_name DragScroll
extends Node
## Drag scrolling for a ScrollContainer full of controls that take the mouse (cards, buttons),
## with a finger or a mouse, and a short glide after letting go. Taps still reach the controls:
## a press only becomes a scroll after DRAG_START px of travel, and once it has, `dragged` stays
## true until the next press so the release is not taken for a tap.
##
##   var ds := DragScroll.attach(self, scroll)
##   cv.tapped.connect(func(_v): if not ds.dragged: _open(id))
##
## Input is read in _input, before the controls, so a drag that starts on a card still scrolls.
## It is ignored while something covers the list (a CardViewer, a dialog overlay added to the
## host after the list) or while `blocked` returns true (e.g. an OptionButton popup is open).
## The mouse wheel is left to the ScrollContainer.

const DRAG_START := 10.0          # travel before a press becomes a scroll
const STOP_US := 80000            # finger held still this long before lifting: no glide
const OFF := Vector2(-100000, -100000)

var scroll: ScrollContainer
var host: Control                 # the screen holding the list (overlays are its children)
var blocked := Callable()         # optional: returns true when the list should not scroll
var dragged := false              # a drag happened since the last press: the release is no tap

var _press := false
var _press_pos := Vector2.ZERO
var _press_scroll := 0.0
var _fling := 0.0                 # px per second, decays after a drag ends
var _last := 0.0
var _last_t := 0


## Add drag scrolling to `sc`, a list inside `p_host`. Returns the helper (a child of the host).
static func attach(p_host: Control, sc: ScrollContainer, p_blocked: Callable = Callable()) -> DragScroll:
	var d := DragScroll.new()
	d.name = "DragScroll"
	d.host = p_host
	d.scroll = sc
	d.blocked = p_blocked
	p_host.add_child(d)
	return d


## Scroll along x when the list only scrolls sideways, otherwise along y.
func _horizontal() -> bool:
	return scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED \
		and scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED


func _axis(p: Vector2) -> float:
	return p.x if _horizontal() else p.y


func _get_scroll() -> float:
	return float(scroll.scroll_horizontal if _horizontal() else scroll.scroll_vertical)


func _set_scroll(v: float) -> void:
	if _horizontal():
		scroll.scroll_horizontal = int(v)
	else:
		scroll.scroll_vertical = int(v)


## Stop any glide (e.g. when the list is refilled and jumps back to the top).
func stop() -> void:
	_fling = 0.0
	_press = false


func _input(event: InputEvent) -> void:
	if scroll == null or not is_instance_valid(scroll) or not scroll.is_visible_in_tree():
		_press = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragged = false
			_fling = 0.0
			_press = scroll.get_global_rect().has_point(event.position) and not _covered(event.position)
			_press_pos = event.position
			_press_scroll = _get_scroll()
			_last = _axis(event.position)
			_last_t = Time.get_ticks_usec()
		elif _press:
			_press = false
			if Time.get_ticks_usec() - _last_t > STOP_US:
				_fling = 0.0
	elif event is InputEventMouseMotion and _press:
		var d := _axis(event.position) - _axis(_press_pos)
		var starting := false
		if not dragged and absf(d) > DRAG_START:
			dragged = true
			starting = true
			_cancel_holds(scroll)
		if dragged:
			_set_scroll(_press_scroll - d)
			var now := Time.get_ticks_usec()
			var dt := maxf(0.001, (now - _last_t) / 1000000.0)
			_fling = lerpf(_fling, -(_axis(event.position) - _last) / dt, 0.5)
			_last = _axis(event.position)
			_last_t = now
			if starting:
				# Let this one motion through, moved far away and without travel: the control the
				# press went to (a Button, a CheckButton, a card) sees the pointer leave it, so the
				# release does not press or toggle it, and the container does not scroll twice.
				event.position = OFF
				event.global_position = OFF
				event.relative = Vector2.ZERO
				event.screen_relative = Vector2.ZERO
			else:
				scroll.get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and dragged and _press:
		scroll.get_viewport().set_input_as_handled()     # no second scroll from the container


func _process(delta: float) -> void:
	if _press or absf(_fling) < 20.0 or scroll == null or not is_instance_valid(scroll):
		return
	var before := _get_scroll()
	_set_scroll(before + _fling * delta)
	_fling *= pow(0.03, delta)
	if _get_scroll() == before:
		_fling = 0.0                                      # reached an end


## A press there falls on something over the list rather than on the list itself.
func _covered(p: Vector2) -> bool:
	if blocked.is_valid() and blocked.call():
		return true
	if host == null or not is_instance_valid(host):
		return false
	# the host's child that holds the list; anything visible added after it may cover it
	var branch: Node = scroll
	while branch != null and branch.get_parent() != host:
		branch = branch.get_parent()
	if branch == null:
		return false
	for i in range(branch.get_index() + 1, host.get_child_count()):
		var c := host.get_child(i)
		if c is Control and c.visible and c.mouse_filter != Control.MOUSE_FILTER_IGNORE \
				and c.get_global_rect().has_point(p):
			return true
	return false


## No long press (and no tap on release) for whatever the finger went down on.
static func _cancel_holds(n: Node) -> void:
	for c in n.get_children():
		if c is CardView:
			c._holding = false
		_cancel_holds(c)
