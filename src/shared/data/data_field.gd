class_name DataField
extends RefCounted
## One field of a data table: its kind, whether it is required, and its limits
## (docs/03-data-formats.md sections 3 and 4). Built with small chained calls,
## for example DataField.of("level", DataField.Kind.INT).between(1, 99).

enum Kind {
	INT,          ## Whole number; JSON numbers with a fraction are rejected (03-D06).
	FLOAT,        ## Positions, sizes and other non-rule numbers.
	BOOL,
	ID,           ## Lowercase snake_case identifier (03-D03).
	TEXT,         ## English base text (03-D02).
	ENUM,         ## One of options.
	ENUM_LIST,    ## Array of values from options.
	REF,          ## ID of an entry in ref_table, checked after all tables load.
	REF_LIST,     ## Array of IDs in ref_table.
	INT_PAIR,     ## [low, high] with low <= high.
	WEIGHT,       ## Displayed weight with at most one decimal, stored in tenths.
	CHANCE,       ## Percentage with at most two decimals, stored per 10000.
	PER_LEVEL_INT, ## One int for every level, or an array with one value per level.
	OBJECT,       ## Nested object described by sub_fields.
}

var name: String
var kind: Kind
var required: bool = true
var min_value: float = -INF
var max_value: float = INF
var options: PackedStringArray = []
var ref_table: String = ""
var sub_fields: Array[DataField] = []
## For PER_LEVEL_INT: the field in the same entry that holds the maximum level.
var levels_field: String = ""


static func of(field_name: String, field_kind: Kind) -> DataField:
	var field: DataField = DataField.new()
	field.name = field_name
	field.kind = field_kind
	return field


func optional() -> DataField:
	required = false
	return self


func between(low: float, high: float) -> DataField:
	min_value = low
	max_value = high
	return self


func one_of(values: PackedStringArray) -> DataField:
	options = values
	return self


func refers_to(table: String) -> DataField:
	ref_table = table
	return self


func with_fields(fields: Array[DataField]) -> DataField:
	sub_fields = fields
	return self


func per_level_of(max_level_field: String) -> DataField:
	levels_field = max_level_field
	return self
