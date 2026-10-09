class_name CharacterRecord
extends RefCounted
## A character as the server keeps it (docs/03-data-formats.md section 8.3).
## Ids point at data tables; the save file format comes with M0-e.

var char_id: int = 0
var account_id: int = 0
var name: String = ""
var created_at: String = ""
var last_saved_at: String = ""
var job: String = ""
var gender: String = "female"
var hair_style: String = ""
var hair_color: String = ""
var eye_color: String = ""
## blendshape name -> weight 0..1
var face_shapes: Dictionary = {}
var map: String = ""
var position: Vector3 = Vector3.ZERO
var facing_deg: float = 0.0
## Changed since the last save; autosave writes only these (02-D17).
var dirty: bool = false


## A new character with the defaults in data/rules new_character, standing on
## the start point (docs/03 section 8.3: first single-player start).
static func create_new(id: int, account: int, character_name: String, catalog: DataCatalog, start: Transform3D) -> CharacterRecord:
	var rules: DataEntry = catalog.rules()
	var defaults: Dictionary = rules.get_object("new_character")
	var record: CharacterRecord = CharacterRecord.new()
	record.char_id = id
	record.account_id = account
	record.name = character_name
	record.created_at = Time.get_datetime_string_from_system(true) + "Z"
	record.last_saved_at = record.created_at
	record.job = str(defaults.get("job", ""))
	record.gender = str(defaults.get("gender", "female"))
	record.hair_style = str(defaults.get("hair_style", ""))
	record.hair_color = str(defaults.get("hair_color", ""))
	record.eye_color = str(defaults.get("eye_color", ""))
	record.map = rules.get_text("start_map")
	record.position = start.origin
	record.facing_deg = MapLogic.facing_of(start)
	return record
