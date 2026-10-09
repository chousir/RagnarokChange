extends Node3D
## A test scene for the screenshot mode and the renderer comparison (docs/11
## M0-f, 01-D15): a town-sized block of buildings, crowds of placeholder
## characters, props and full lighting, built in code so it needs no art. Its
## numbers are only a baseline until the real maps exist.

const CHARACTER_SCENE := "res://assets/characters/placeholder_character/placeholder_character.tscn"
const MONSTER_SCENE := "res://assets/monsters/placeholder_monster/placeholder_monster.tscn"
const SEED := 20261010

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = SEED
	var walls: Array[StandardMaterial3D] = [_material(Color(0.78, 0.74, 0.66)), _material(Color(0.62, 0.58, 0.52)), _material(Color(0.7, 0.66, 0.6))]
	var roofs: Array[StandardMaterial3D] = [_material(Color(0.45, 0.18, 0.12)), _material(Color(0.3, 0.32, 0.38))]
	_add_buildings(walls, roofs)
	# One character fixed at the centre, facing the close-up camera (+Z).
	var hero_scene: PackedScene = load(CHARACTER_SCENE)
	var hero: Node3D = hero_scene.instantiate()
	hero.rotation.y = PI
	add_child(hero)
	_add_crowd(CHARACTER_SCENE, 200, 45.0)
	_add_crowd(MONSTER_SCENE, 60, 80.0)
	_add_props()


func _add_buildings(walls: Array[StandardMaterial3D], roofs: Array[StandardMaterial3D]) -> void:
	for row: int in 12:
		for column: int in 12:
			if absi(row - 6) <= 1 and absi(column - 6) <= 1:
				continue
			var size: Vector3 = Vector3(_rng.randf_range(6.0, 11.0), _rng.randf_range(5.0, 14.0), _rng.randf_range(6.0, 11.0))
			var base: Vector3 = Vector3((column - 6) * 16.0, 0.0, (row - 6) * 16.0)
			var body: MeshInstance3D = _box(size, walls[(row + column) % walls.size()])
			body.position = base + Vector3(0.0, size.y / 2.0, 0.0)
			add_child(body)
			var roof: MeshInstance3D = _box(Vector3(size.x + 0.6, 1.2, size.z + 0.6), roofs[(row * column) % roofs.size()])
			roof.position = base + Vector3(0.0, size.y + 0.6, 0.0)
			add_child(roof)


func _add_crowd(scene_path: String, count: int, radius: float) -> void:
	var scene: PackedScene = load(scene_path)
	for index: int in count:
		var instance: Node3D = scene.instantiate()
		var angle: float = _rng.randf() * TAU
		var distance: float = sqrt(_rng.randf()) * radius
		instance.position = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		instance.rotation.y = _rng.randf() * TAU
		add_child(instance)


func _add_props() -> void:
	var wood: StandardMaterial3D = _material(Color(0.42, 0.3, 0.2))
	var stone: StandardMaterial3D = _material(Color(0.55, 0.55, 0.57))
	for index: int in 400:
		var prop: MeshInstance3D = MeshInstance3D.new()
		if index % 2 == 0:
			var barrel: CylinderMesh = CylinderMesh.new()
			barrel.top_radius = 0.35
			barrel.bottom_radius = 0.35
			barrel.height = 0.9
			barrel.material = wood
			prop.mesh = barrel
		else:
			var rock: SphereMesh = SphereMesh.new()
			rock.radius = 0.5
			rock.height = 0.7
			rock.material = stone
			prop.mesh = rock
		prop.position = Vector3(_rng.randf_range(-95.0, 95.0), 0.4, _rng.randf_range(-95.0, 95.0))
		add_child(prop)


static func _box(size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	return instance


static func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material
