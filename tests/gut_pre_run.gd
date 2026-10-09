extends GutHookScript
## Runs once before any test.
##
## Terrain3D 1.0.2 calls instance_reset_physics_interpolation(), which Godot
## 4.7 marks deprecated and reports once per process. GUT 9.7.1 counts engine
## warnings as errors, so whichever test first loaded a map with terrain would
## fail. Making one terrain here takes that single report outside every test;
## any other warning or error still fails its test.


func run() -> void:
	var main: Node = gut
	var tree: SceneTree = main.get_tree()
	var camera: Camera3D = Camera3D.new()
	tree.root.add_child(camera)
	camera.make_current()
	var terrain: Terrain3D = Terrain3D.new()
	tree.root.add_child(terrain)
	terrain.free()
	camera.free()
