class_name VisualConfig
extends Resource
## How the client shows one visual_id (docs/03-data-formats.md section 5): the
## scene to instance and the numbers around it. Saved as
## assets/<category>/<visual_id>/<visual_id>.visual.tres. Equipment offsets,
## hair modes and monster motion parameters join as M3 to M6 need them
## (docs/05 section 4.2, docs/07 section 7).

## Model scene; until the art arrives it is a placeholder scene.
@export var scene: PackedScene
## Height of the name plate above the feet.
@export var nameplate_height_m: float = 2.0
## Simple shape for mouse picking, a bit larger than the model (09 section 7).
@export var pick_radius_m: float = 0.45
@export var pick_height_m: float = 1.9
## True while scene is a stand-in; lists of missing art are built from it.
@export var is_placeholder: bool = false
