extends Control
## Contact sheet of FigurePainter output: card looks large (as on the encounter screen) and
## the same looks at map size (as wanderers), plus hero looks.
##   xvfb-run -a godot --path . res://tests/figure_sheet.tscn -- <out.png> [page]

const PAGES := [
	["sanctum_c_008", "sanctum_c_003", "sanctum_c_006", "sanctum_u_005", "sanctum_c_023", "sanctum_r_012",
	"abyss_c_001", "abyss_c_004", "abyss_c_005", "abyss_c_011", "abyss_c_002", "abyss_u_003",
	"wild_c_002", "wild_r_001", "wild_c_010", "wild_c_021", "wild_c_007", "wild_u_008",
	"revel_c_003", "revel_c_011", "revel_c_008", "revel_c_007", "revel_u_003", "revel_c_001"],
	["lyceum_c_005", "lyceum_c_006", "lyceum_c_008", "lyceum_c_028", "lyceum_c_004", "lyceum_u_001",
	"machine_c_003", "machine_c_007", "machine_c_001", "machine_c_006", "machine_c_011", "machine_r_001",
	"sanctum_c_010", "sanctum_c_001", "abyss_u_007", "abyss_m_002", "abyss_c_027", "abyss_u_006",
	"wild_c_004", "wild_r_005", "wild_c_008", "revel_c_012", "revel_r_005", "lyceum_c_001"],
	["sanctum_c_008", "sanctum_c_004", "lyceum_c_005", "revel_c_003", "abyss_c_010"],
	["wild_u_005", "revel_c_011", "abyss_c_011", "machine_c_003", "lyceum_c_006"],
]

var page := 0
var looks: Array = []
var timing := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else OS.get_user_data_dir() + "/shots/figures.png"
	page = int(args[1]) if args.size() > 1 else 0
	get_window().size = Vector2i(1600, 1000)
	size = Vector2(1600, 1000)
	for id in PAGES[page]:
		looks.append(CardDB.get_card(id))
	if page >= 2:
		pass
	elif page == 0:
		for f in ["sanctum", "revel"]:
			var sh: Dictionary = Hero.classic_sheet(f)
			looks.append({"faction": f, "subtype": GameState.HEROES[f]["subtype"], "name": "Hero", "look": sh["look"]})
	else:
		for f in ["lyceum", "machine"]:
			var sh: Dictionary = Hero.classic_sheet(f)
			looks.append({"faction": f, "subtype": GameState.HEROES[f]["subtype"], "name": "Hero", "look": sh["look"]})
	queue_redraw()
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	timing = true
	queue_redraw()
	await RenderingServer.frame_post_draw
	get_tree().quit()


func _draw() -> void:
	if timing:
		# paint every look many times, as the map does for its wanderers
		var best := INF
		for batch in 6:
			var t0 := Time.get_ticks_usec()
			var n := 0
			for r in 5:
				for lk in looks:
					FigurePainter.paint(self, lk, Transform2D(0, Vector2(-500, -500)), 74, 1.0, 1.0)
					n += 1
			best = minf(best, float(Time.get_ticks_usec() - t0) / n)
		print("paint avg us (best batch): ", int(best))
		return
	var vs := get_viewport_rect().size
	Tapestry.draw_parchment(self, Rect2(Vector2.ZERO, vs))
	var cols := 9 if page < 2 else 5
	var cw := vs.x / cols
	if page >= 2:
		for i in looks.size():
			var feet := Vector2(cw * (i + 0.5), vs.y - 30)
			FigurePainter.paint(self, looks[i], Transform2D(0, feet), 600, 1.0, 1.0)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	for i in looks.size():
		var lk: Dictionary = looks[i]
		var col := i % cols
		var row := i / cols
		var feet := Vector2(cw * (col + 0.5), 10 + (row + 1) * 222.0)
		draw_colored_polygon(Tapestry.ellipse(feet + Vector2(0, 3), 40, 8, 16), Color(0, 0, 0, 0.2))
		FigurePainter.paint(self, lk, Transform2D(0, feet), 175, 1.0 if i % 2 == 0 else -1.0, 1.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		var nm := String(lk.get("name", ""))
		draw_string(Tapestry.font("book"), feet + Vector2(-cw * 0.5 + 4, 16), nm.substr(0, 22), HORIZONTAL_ALIGNMENT_CENTER, cw - 8, 13, Tapestry.INK)
	# map size row
	for i in looks.size():
		var feet := Vector2(26 + i * 47.0, vs.y - 12)
		FigurePainter.paint(self, looks[i], Transform2D(0, feet), 64, 1.0 if i % 2 == 0 else -1.0, 1.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
