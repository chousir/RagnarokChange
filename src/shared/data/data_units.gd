class_name DataUnits
extends RefCounted
## Unit conversions done once at load time (docs/03-data-formats.md section 3.3).
## Data keeps RO units (cells, milliseconds per cell) so values can be checked
## against RO; running code only sees meters and meters per second.


static func cells_to_meters(cells: float, cell_size_m: float) -> float:
	return cells * cell_size_m


static func ms_per_cell_to_meters_per_second(ms_per_cell: int, cell_size_m: float) -> float:
	return cell_size_m / (ms_per_cell / 1000.0)


## Weight is stored in tenths (03-D06): 400 means 40.0 shown in game.
static func weight_tenths_to_display(tenths: int) -> float:
	return tenths / 10.0


## Chances are stored per 10000 (03-D06): 7000 means 70%.
static func chance_to_percent(per_10000: int) -> float:
	return per_10000 / 100.0
