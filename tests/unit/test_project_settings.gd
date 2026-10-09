extends GutTest
## Project settings that other rules depend on (docs/01-architecture.md section 10,
## docs/03-data-formats.md section 9.1).

const ERROR_LEVEL := 2


func test_untyped_and_unsafe_code_is_an_error() -> void:
	for warning: String in ["untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument"]:
		var level: int = ProjectSettings.get_setting("debug/gdscript/warnings/" + warning, 0)
		assert_eq(level, ERROR_LEVEL, warning)


func test_user_folder_is_fixed() -> void:
	var uses_custom_dir: bool = ProjectSettings.get_setting("application/config/use_custom_user_dir", false)
	var dir_name: String = ProjectSettings.get_setting("application/config/custom_user_dir_name", "")
	assert_true(uses_custom_dir)
	assert_eq(dir_name, "RagnarokChange")
