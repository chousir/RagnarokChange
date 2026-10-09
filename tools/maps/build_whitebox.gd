extends SceneTree
## Builds the white-box maps (docs/11 M1-a, docs/08). Run in two steps with an
## import between them; tools/scripts/build_whitebox.ps1 does all of it:
##   godot --headless --path . -s res://tools/maps/build_whitebox.gd ++ --stage=textures
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/maps/build_whitebox.gd ++ --stage=maps [--map=<id>]
## The output is the same every run: every random choice is seeded.

const SEED := 20261010


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--") and argument.contains("="):
			options[argument.substr(2).get_slice("=", 0)] = argument.substr(argument.find("=") + 1)
	var stage: String = str(options.get("stage", ""))
	match stage:
		"textures":
			for path: String in WhiteboxTextures.generate():
				print("whitebox: wrote %s" % path)
			quit(0)
		"maps":
			quit(await _build_maps(str(options.get("map", "all"))))
		_:
			push_error("whitebox: use --stage=textures or --stage=maps")
			quit(2)


func _build_maps(only: String) -> int:
	if not ResourceLoader.exists(WhiteboxKit.TERRAIN_ASSETS):
		var made: Error = WhiteboxTextures.make_terrain_assets(WhiteboxKit.TERRAIN_ASSETS)
		if made != OK:
			push_error("whitebox: cannot save %s (error %d)" % [WhiteboxKit.TERRAIN_ASSETS, made])
			return 1
	# Terrain3D looks for the active camera as soon as it enters the tree.
	var camera: Camera3D = Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	var layouts: Array[WhiteboxLayout] = [KronenbergLayout.new(), SouthFieldLayout.new()]
	for layout: WhiteboxLayout in layouts:
		if only != "all" and only != layout.map_id:
			continue
		var started: int = Time.get_ticks_msec()
		layout.prepare()
		var kit: WhiteboxKit = WhiteboxKit.new(layout, SEED)
		layout.build(kit)
		var placed: int = kit.buildings.get_child_count()
		kit.build_terrain(self)
		await process_frame
		var chunks: int = kit.bake_navigation()
		var problems: PackedStringArray = kit.save_scenes()
		kit.map_root.get_parent().remove_child(kit.map_root)
		kit.map_root.free()
		kit.logic_root.free()
		for problem: String in problems:
			push_error("whitebox: %s" % problem)
		if not problems.is_empty():
			return 1
		print("whitebox: %s done in %.1f s: %d pieces, %d navigation chunks, %d obstructions" % [layout.map_id, (Time.get_ticks_msec() - started) / 1000.0, placed, chunks, kit.obstructions.size()])
	return 0
