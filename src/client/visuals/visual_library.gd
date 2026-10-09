class_name VisualLibrary
extends RefCounted
## Finds visual configs by the fixed path rule and caches them (docs/03 section
## 5). A visual_id with no config shows the category's placeholder and logs an
## error once, so a missing file never stops the client; the client data test
## keeps that from happening at all.

const SIDE := "CL"
const ROOT := "res://assets"
const CHARACTERS := "characters"
const MONSTERS := "monsters"
const EQUIPMENT := "equipment"
const PLACEHOLDERS := {
	"characters": "placeholder_character",
	"monsters": "placeholder_monster",
	"equipment": "placeholder_weapon",
}

## "category/visual_id" -> VisualConfig
var _cache: Dictionary = {}
var _reported: Dictionary = {}


static func path_for(category: String, visual_id: String) -> String:
	return "%s/%s/%s/%s.visual.tres" % [ROOT, category, visual_id, visual_id]


static func exists(category: String, visual_id: String) -> bool:
	return ResourceLoader.exists(path_for(category, visual_id))


## The config for visual_id, or the category's placeholder when it is missing.
func get_visual(category: String, visual_id: String) -> VisualConfig:
	var key: String = "%s/%s" % [category, visual_id]
	if _cache.has(key):
		var cached: VisualConfig = _cache[key]
		return cached
	var config: VisualConfig = _load(category, visual_id)
	if config == null:
		if not _reported.has(key):
			_reported[key] = true
			Log.error(SIDE, "asset", "no visual config at %s; showing a placeholder" % path_for(category, visual_id))
		var placeholder_id: String = PLACEHOLDERS.get(category, "")
		config = _load(category, placeholder_id)
	if config != null:
		_cache[key] = config
	return config


static func _load(category: String, visual_id: String) -> VisualConfig:
	if visual_id.is_empty() or not exists(category, visual_id):
		return null
	var config: VisualConfig = load(path_for(category, visual_id))
	return config
