class_name KeyBinding
extends RefCounted
## Key bindings as plain text (docs/03-data-formats.md section 9.2): "F1",
## "Ctrl+1", "Alt+A", "Mouse:Right", "Wheel:Up". The settings file never holds
## InputEvent objects, so people can read and edit it. Keys are physical keys
## named by the US layout, so WASD stays in place on any keyboard layout.

const MOUSE_PREFIX := "Mouse:"
const WHEEL_PREFIX := "Wheel:"
const MOUSE_NAMES := {
	"Left": MOUSE_BUTTON_LEFT,
	"Right": MOUSE_BUTTON_RIGHT,
	"Middle": MOUSE_BUTTON_MIDDLE,
	"Extra1": MOUSE_BUTTON_XBUTTON1,
	"Extra2": MOUSE_BUTTON_XBUTTON2,
}
const WHEEL_NAMES := {
	"Up": MOUSE_BUTTON_WHEEL_UP,
	"Down": MOUSE_BUTTON_WHEEL_DOWN,
	"Left": MOUSE_BUTTON_WHEEL_LEFT,
	"Right": MOUSE_BUTTON_WHEEL_RIGHT,
}


## The event a text names, or null when the text is not a binding.
static func to_event(text: String) -> InputEvent:
	if text.begins_with(MOUSE_PREFIX) or text.begins_with(WHEEL_PREFIX):
		var wheel: bool = text.begins_with(WHEEL_PREFIX)
		var names: Dictionary = WHEEL_NAMES if wheel else MOUSE_NAMES
		var button_name: String = text.trim_prefix(WHEEL_PREFIX if wheel else MOUSE_PREFIX)
		if not names.has(button_name):
			return null
		var button: InputEventMouseButton = InputEventMouseButton.new()
		var index: int = names[button_name]
		button.button_index = index as MouseButton
		return button
	var code: int = OS.find_keycode_from_string(text)
	var key_part: int = code & KEY_CODE_MASK
	if key_part == KEY_NONE:
		return null
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = key_part as Key
	key.shift_pressed = (code & KEY_MASK_SHIFT) != 0
	key.alt_pressed = (code & KEY_MASK_ALT) != 0
	key.ctrl_pressed = (code & KEY_MASK_CTRL) != 0
	key.meta_pressed = (code & KEY_MASK_META) != 0
	# Only the canonical spelling is a binding, so files stay unambiguous.
	if to_text(key) != text:
		return null
	return key


## Text for an event; empty for events that cannot be bindings.
static func to_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var key: InputEventKey = event
		return OS.get_keycode_string(key.get_physical_keycode_with_modifiers())
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		for button_name: Variant in MOUSE_NAMES:
			var index: int = MOUSE_NAMES[button_name]
			if index == button.button_index:
				return MOUSE_PREFIX + str(button_name)
		for button_name: Variant in WHEEL_NAMES:
			var index: int = WHEEL_NAMES[button_name]
			if index == button.button_index:
				return WHEEL_PREFIX + str(button_name)
	return ""


static func is_valid(text: String) -> bool:
	return to_event(text) != null
