class_name DataEntry
extends RefCounted
## One validated, read-only entry of a data table (docs/01-architecture.md
## section 10: data objects are read-only after loading).

var table: String
var id: String
## Data file the entry came from, relative to the data folder, for error messages.
var source: String
## Position of the id in the table's sorted id list; the u16 used on the wire (03-D04).
var index: int = -1
var _values: Dictionary = {}


static func make(table_name: String, values: Dictionary, source_file: String) -> DataEntry:
	var entry: DataEntry = DataEntry.new()
	entry.table = table_name
	entry.id = str(values.get("id", ""))
	entry.source = source_file
	entry._values = values
	return entry


func has_value(key: String) -> bool:
	return _values.has(key)


## Deep copy of the normalized values, for checks that walk every field.
func to_dictionary() -> Dictionary:
	return _values.duplicate(true)


## Adds meter values next to RO cell values, once at load time (docs/03 section
## 3.3): a field ending in _cells gets a twin ending in _m, and one ending in
## _ms_per_cell gets a twin ending in _mps, so running code never sees cells.
func convert_units(cell_size_m: float) -> void:
	for key: String in _values.keys():
		var value: Variant = _values[key]
		if key.ends_with("_ms_per_cell") and value is int:
			var ms_per_cell: int = value
			_values[key.trim_suffix("_ms_per_cell") + "_mps"] = DataUnits.ms_per_cell_to_meters_per_second(ms_per_cell, cell_size_m)
		elif key.ends_with("_cells"):
			var meters_key: String = key.trim_suffix("_cells") + "_m"
			if value is int:
				var cells: int = value
				_values[meters_key] = DataUnits.cells_to_meters(cells, cell_size_m)
			elif value is PackedInt32Array:
				var cell_list: PackedInt32Array = value
				var meters: PackedFloat64Array = []
				for cell_count: int in cell_list:
					meters.append(DataUnits.cells_to_meters(cell_count, cell_size_m))
				_values[meters_key] = meters


func get_floats(key: String) -> PackedFloat64Array:
	var value: Variant = _values.get(key, PackedFloat64Array())
	var result: PackedFloat64Array = value
	return result


func get_int(key: String, default_value: int = 0) -> int:
	var value: Variant = _values.get(key, default_value)
	var result: int = value
	return result


func get_float(key: String, default_value: float = 0.0) -> float:
	var value: Variant = _values.get(key, default_value)
	var result: float = value
	return result


func get_text(key: String, default_value: String = "") -> String:
	var value: Variant = _values.get(key, default_value)
	var result: String = value
	return result


func get_bool(key: String, default_value: bool = false) -> bool:
	var value: Variant = _values.get(key, default_value)
	var result: bool = value
	return result


func get_strings(key: String) -> PackedStringArray:
	var value: Variant = _values.get(key, PackedStringArray())
	var result: PackedStringArray = value
	return result


func get_int_pair(key: String) -> PackedInt32Array:
	var value: Variant = _values.get(key, PackedInt32Array())
	var result: PackedInt32Array = value
	return result


func get_object(key: String) -> Dictionary:
	var value: Variant = _values.get(key, {})
	var result: Dictionary = value
	return result
