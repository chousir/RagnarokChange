extends Node
## Autoload holding the read-only game data (docs/01-architecture.md section 9.1).
## It has no game state, so the server and every client in one process can share it.

const DATA_ROOT := "res://data"

var catalog: DataCatalog = DataCatalog.new()


func _ready() -> void:
	load_data(DATA_ROOT)


## Loads the data folder and reports every problem through Log. Returns true on success.
func load_data(root: String) -> bool:
	var loaded: DataCatalog = DataCatalog.new()
	var ok: bool = loaded.load_from_dir(root)
	for problem: String in loaded.errors:
		Log.error("", "data", problem)
	catalog = loaded
	return ok
