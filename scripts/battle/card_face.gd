class_name CardFace
extends RefCounted
## A small card as it lies on the battlefield: its art, its name (cut with "…" when long),
## power and toughness, and a count or counter badge. Creatures, lands, relics, possessions
## and tokens are all drawn with it, so everything on the table reads the same way.


## Paint card `c` in rect `r` of canvas item `ci`. Options:
##   pt: "3/3" (shown when set), pt_col, badge: "×3" or "+1/+1", alpha, dim (behind or tapped),
##   frame: an outline colour (marks), flash: [Color, 0..1].
static func paint(ci: CanvasItem, r: Rect2, c: Dictionary, opt: Dictionary = {}) -> void:
	var a: float = opt.get("alpha", 1.0)
	var faith := String(c.get("faction", "machine"))
	var demon: bool = String(c.get("subtype", "")).contains("Demon") and c.get("type", "") != "creature"
	var edge := Color(0.42, 0.02, 0.10) if demon else Tapestry.INK
	ci.draw_rect(r, Color(edge, a))
	var inner := r.grow(-2)
	ci.draw_rect(inner, Color(CardView.body_color(faith), a))
	var book := Tapestry.font("book")
	var fs := clampi(int(inner.size.x / 7.5), 11, 14)
	var name_h := fs + 5.0
	# the art fills the card under the name
	var art_r := Rect2(inner.position + Vector2(2, name_h), Vector2(inner.size.x - 4, inner.size.y - name_h - 2))
	var tex: Texture2D = CardView._art_texture(String(c.get("art", "")))
	if tex and art_r.size.x > 4 and art_r.size.y > 4:
		var ts := tex.get_size()
		var k := maxf(art_r.size.x / ts.x, art_r.size.y / ts.y)
		var src_size := art_r.size / k
		var src := Rect2((ts - src_size) * Vector2(0.5, 0.3), src_size)
		ci.draw_texture_rect_region(tex, art_r, src, Color(1, 1, 1, a))
	else:
		# a token or a card without art: parchment and its faith's sigil
		ci.draw_rect(art_r, Color(Tapestry.PARCHMENT, a))
		UIKit.draw_sigil(ci, faith, art_r.get_center(), minf(art_r.size.x, art_r.size.y) * 0.28, Color(Tapestry.RUBRIC, a), 1.6)
	if opt.get("dim", false):
		ci.draw_rect(art_r, Color(0, 0, 0, 0.28 * a))
	# the name, on a parchment strip, cut with an ellipsis
	var name_r := Rect2(inner.position, Vector2(inner.size.x, name_h))
	ci.draw_rect(name_r, Color(Tapestry.PARCHMENT_LIGHT, a))
	var nm := fit(I18n.t(String(c.get("name", ""))), book, fs, name_r.size.x - 6)
	ci.draw_string(book, name_r.position + Vector2(3, fs + 1), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Tapestry.INK, a))
	# power and toughness, bottom right
	var pt := String(opt.get("pt", ""))
	if pt != "":
		var pfs := clampi(fs + 2, 13, 16)
		var pw := book.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, pfs).x + 10
		var pr := Rect2(inner.end - Vector2(pw + 2, pfs + 7), Vector2(pw, pfs + 5))
		ci.draw_rect(pr, Color(Tapestry.PARCHMENT_LIGHT, a))
		ci.draw_rect(pr, Color(Tapestry.INK, a), false, 1.5)
		ci.draw_string(book, pr.position + Vector2(5, pfs), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, pfs, Color(opt.get("pt_col", Tapestry.INK), a))
	# a count ("×3") or counters ("+1/+1"), bottom left
	var badge := String(opt.get("badge", ""))
	if badge != "":
		var bfs := clampi(fs + 1, 12, 15)
		var bw := book.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs).x + 10
		var br := Rect2(inner.position + Vector2(2, inner.size.y - bfs - 8), Vector2(bw, bfs + 5))
		ci.draw_rect(br, Color(opt.get("badge_col", Color(0.10, 0.30, 0.10)), 0.92 * a))
		ci.draw_string(book, br.position + Vector2(5, bfs), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs, Color(Tapestry.WHITE, a))
	var fl: Array = opt.get("flash", [])
	if fl.size() == 2 and float(fl[1]) > 0.0:
		ci.draw_rect(inner, Color(fl[0], 0.45 * float(fl[1]) * a))
	var frame: Color = opt.get("frame", Color.TRANSPARENT)
	if frame.a > 0.0:
		ci.draw_rect(r.grow(1), Color(frame, 0.95 * a), false, 3.5)


## `s` cut to fit `w` pixels, ending in "…" when it had to be cut.
static func fit(s: String, font: Font, fs: int, w: float) -> String:
	if font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= w:
		return s
	var t := s
	while t.length() > 1 and font.get_string_size(t + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w:
		t = t.substr(0, t.length() - 1)
	return t.strip_edges() + "…"


## Paint a card turned a quarter (tapped) inside the upright rect `r`: it lies across the
## middle of the slot, scaled to fit its width.
static func paint_tapped(ci: CanvasItem, r: Rect2, c: Dictionary, opt: Dictionary = {}) -> void:
	var s := minf(r.size.x / r.size.y, 1.0)      # turned, its height must fit the slot's width
	var card_size := Vector2(r.size.x * s, r.size.y * s)
	ci.draw_set_transform(r.get_center(), PI * 0.5, Vector2.ONE)
	var o := opt.duplicate()
	o["dim"] = true
	paint(ci, Rect2(-card_size * 0.5, card_size), c, o)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
