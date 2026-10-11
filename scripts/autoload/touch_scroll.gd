extends Node
## Every scrollable list in the game scrolls by finger (or mouse) drag, up and down, not only
## by its bar: whenever a ScrollContainer joins the tree, it gets a DragScroll helper unless a
## screen already attached one itself. A list inside another list that scrolls the same way is
## left to the outer one, so a drag never scrolls twice.


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(n: Node) -> void:
	if n is ScrollContainer:
		_attach.call_deferred(n)


func _attach(sc: ScrollContainer) -> void:
	if not is_instance_valid(sc) or not sc.is_inside_tree() or sc.has_meta("drag_scroll"):
		return
	var p := sc.get_parent()
	while p != null:
		if p is ScrollContainer and _same_axis(p, sc):
			return
		p = p.get_parent()
	# the screen holding the list: its topmost Control ancestor (overlays become its children)
	var host: Control = null
	var a: Node = sc
	while a != null and a is Control:
		host = a
		a = a.get_parent()
	if host == null or host == sc:
		host = sc
	DragScroll.attach(host, sc)


static func _same_axis(a: ScrollContainer, b: ScrollContainer) -> bool:
	var av := a.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
	var bv := b.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
	return av == bv
