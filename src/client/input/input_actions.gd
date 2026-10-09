class_name InputActions
extends RefCounted
## Every rebindable action and its default keys (docs/09-camera-controls.md
## sections 6.2 and 6.3). Mouse clicks and drags for the camera and picking are
## handled by their own code, not here.

const DEFAULTS := {
	"move_forward": ["W"],
	"move_back": ["S"],
	"move_left": ["A"],
	"move_right": ["D"],
	"walk_toggle": ["Slash"],
	"camera_reset": ["Home"],
	"target_next": ["Tab"],
	"target_previous": ["Shift+Tab"],
	"target_clear": ["Escape"],
	"attack": ["R"],
	"pick_up": ["F"],
	"skill_bar_1": ["F1"],
	"skill_bar_2": ["F2"],
	"skill_bar_3": ["F3"],
	"skill_bar_4": ["F4"],
	"skill_bar_5": ["F5"],
	"skill_bar_6": ["F6"],
	"skill_bar_7": ["F7"],
	"skill_bar_8": ["F8"],
	"skill_bar_9": ["F9"],
	"sit": ["Insert"],
	"emote_1": ["Alt+1"],
	"emote_2": ["Alt+2"],
	"emote_3": ["Alt+3"],
	"emote_4": ["Alt+4"],
	"emote_5": ["Alt+5"],
	"emote_6": ["Alt+6"],
	"emote_7": ["Alt+7"],
	"emote_8": ["Alt+8"],
	"emote_9": ["Alt+9"],
	"emote_10": ["Alt+0"],
	"window_status": ["Alt+A"],
	"window_items": ["Alt+E"],
	"window_equipment": ["Alt+Q"],
	"window_skills": ["Alt+S"],
	"screenshot": ["Print"],
	"perf_panel": ["Ctrl+F3"],
	"debug_console": ["QuoteLeft"],
}


## Default bindings as action -> PackedStringArray.
static func default_bindings() -> Dictionary:
	var bindings: Dictionary = {}
	for action: Variant in DEFAULTS:
		var texts: Array = DEFAULTS[action]
		bindings[str(action)] = PackedStringArray(texts)
	return bindings


## Puts bindings (action -> texts) into Godot's InputMap.
static func apply(bindings: Dictionary) -> void:
	for action: Variant in bindings:
		var action_name: StringName = StringName(str(action))
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		InputMap.action_erase_events(action_name)
		var texts: PackedStringArray = bindings[action]
		for text: String in texts:
			var event: InputEvent = KeyBinding.to_event(text)
			if event != null:
				InputMap.action_add_event(action_name, event)
