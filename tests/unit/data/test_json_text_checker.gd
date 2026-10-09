extends GutTest
## docs/03-data-formats.md section 3.1: what Godot's JSON parser lets through.


func test_clean_text_has_no_problems() -> void:
	var text: String = '{\n  "table": "maps",\n  "entries": [\n    { "id": "a", "flags": ["town"] },\n    { "id": "b", "flags": [] }\n  ]\n}'
	assert_eq(JsonTextChecker.find_problems(text), PackedStringArray())


func test_duplicate_key_in_one_object_is_found_with_its_line() -> void:
	var text: String = '{\n  "id": "a",\n  "name": "A",\n  "name": "B"\n}'
	var problems: PackedStringArray = JsonTextChecker.find_problems(text)
	assert_eq(problems.size(), 1)
	assert_string_contains(problems[0], "line 4")
	assert_string_contains(problems[0], "\"name\"")


func test_same_key_in_sibling_objects_is_fine() -> void:
	var text: String = '[{ "id": "a" }, { "id": "b" }]'
	assert_eq(JsonTextChecker.find_problems(text), PackedStringArray())


func test_nested_object_keys_do_not_clash_with_the_parent() -> void:
	var text: String = '{ "id": "a", "visual_ids": { "id": "x" }, "name": "A" }'
	assert_eq(JsonTextChecker.find_problems(text), PackedStringArray())


func test_duplicate_key_after_a_nested_object_is_found() -> void:
	var text: String = '{ "id": "a", "visual_ids": { "female": "x" }, "id": "b" }'
	assert_eq(JsonTextChecker.find_problems(text).size(), 1)


func test_trailing_commas_are_found() -> void:
	var text: String = '{\n  "flags": ["town",],\n  "id": "a",\n}'
	var problems: PackedStringArray = JsonTextChecker.find_problems(text)
	assert_eq(problems.size(), 2)
	assert_string_contains(problems[0], "line 2")
	assert_string_contains(problems[1], "line 4")


func test_symbols_inside_strings_are_ignored() -> void:
	var text: String = '{ "note": "a, b } ] {\\"name\\": 1,}", "name": "x" }'
	assert_eq(JsonTextChecker.find_problems(text), PackedStringArray())


func test_string_values_are_not_taken_as_keys() -> void:
	var text: String = '{ "id": "name", "name": "id" }'
	assert_eq(JsonTextChecker.find_problems(text), PackedStringArray())
