class_name WhiteboxTextures
extends RefCounted
## The one ground texture of the white box, made by code (an original asset,
## registered as LicenseRef-Original): a light grey surface with a little grain
## that the terrain colour map tints into grass, paving and dirt. It tiles
## because every wave in it has a whole number of periods across the image.

const FOLDER := "res://assets/textures/whitebox_ground"
const ALBEDO := FOLDER + "/whitebox_ground_albedo.png"
const NORMAL := FOLDER + "/whitebox_ground_normal.png"
const SIZE := 512
const WAVES := 24
const SEED := 20261010
## Terrain3D wants mipmaps on its textures; written before the first import.
const IMPORT_PARAMS := "[params]\n\ncompress/mode=0\nmipmaps/generate=true\nmipmaps/limit=-1\ndetect_3d/compress_to=0\n"


## Writes both PNGs and their import settings. Returns the files written.
static func generate() -> PackedStringArray:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED
	var waves: Array[Vector4] = []
	for index: int in WAVES:
		var frequency: Vector2i = Vector2i(rng.randi_range(-24, 24), rng.randi_range(-24, 24))
		waves.append(Vector4(frequency.x, frequency.y, rng.randf_range(0.0, TAU), 1.0 / (1.0 + Vector2(frequency).length() * 0.25)))
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(SIZE * SIZE)
	var low: float = INF
	var high: float = -INF
	for y: int in SIZE:
		for x: int in SIZE:
			var value: float = 0.0
			for wave: Vector4 in waves:
				value += wave.w * sin(TAU * (wave.x * x + wave.y * y) / SIZE + wave.z)
			heights[y * SIZE + x] = value
			low = minf(low, value)
			high = maxf(high, value)
	var albedo: Image = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var normal: Image = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var height: float = (heights[y * SIZE + x] - low) / (high - low)
			var grey: float = 0.8 + 0.14 * height
			albedo.set_pixel(x, y, Color(grey, grey, grey, height))
			var left: float = heights[y * SIZE + posmod(x - 1, SIZE)]
			var right: float = heights[y * SIZE + posmod(x + 1, SIZE)]
			var up: float = heights[posmod(y - 1, SIZE) * SIZE + x]
			var down: float = heights[posmod(y + 1, SIZE) * SIZE + x]
			var slope: Vector3 = Vector3((left - right) * 0.6, 1.0, (up - down) * 0.6).normalized()
			# OpenGL-style normal map (green up), roughness in alpha.
			normal.set_pixel(x, y, Color(slope.x * 0.5 + 0.5, -slope.z * 0.5 + 0.5, slope.y * 0.5 + 0.5, 0.85))
	var written: PackedStringArray = []
	for pair: Array in [[albedo, ALBEDO], [normal, NORMAL]]:
		var image: Image = pair[0]
		var path: String = pair[1]
		image.save_png(ProjectSettings.globalize_path(path))
		var import_file: FileAccess = FileAccess.open(ProjectSettings.globalize_path(path + ".import"), FileAccess.WRITE)
		import_file.store_string("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[deps]\n\nsource_file=\"%s\"\n\n%s" % [path, IMPORT_PARAMS])
		import_file.close()
		written.append(path)
	return written


## The Terrain3D asset list with the white-box texture; needs the PNGs imported.
static func make_terrain_assets(path: String) -> Error:
	var texture: Terrain3DTextureAsset = Terrain3DTextureAsset.new()
	texture.name = "whitebox_ground"
	texture.albedo_texture = load(ALBEDO)
	texture.normal_texture = load(NORMAL)
	# One tile every 4 m keeps the grain fine.
	texture.uv_scale = 0.25
	var assets: Terrain3DAssets = Terrain3DAssets.new()
	assets.set_texture(0, texture)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	return ResourceSaver.save(assets, path)
