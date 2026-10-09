class_name DataTableSchema
extends RefCounted
## Schema of one data table: its name, the folder under data/ that holds its
## files, the display-name key prefix used by locale/ (docs/03-data-formats.md
## section 7), and its fields.

var table: String
var folder: String
## Prefix of the locale key for entry names, for example "job" for job.novice.name.
## Empty when entries have no display name.
var name_key: String
## Required start of every id, for example "face_" for face shapes. Empty means any id.
var id_prefix: String = ""
var fields: Array[DataField] = []


static func make(table_name: String, folder_name: String, name_key_prefix: String, table_fields: Array[DataField]) -> DataTableSchema:
	var schema: DataTableSchema = DataTableSchema.new()
	schema.table = table_name
	schema.folder = folder_name
	schema.name_key = name_key_prefix
	schema.fields = table_fields
	return schema


func with_id_prefix(prefix: String) -> DataTableSchema:
	id_prefix = prefix
	return self
