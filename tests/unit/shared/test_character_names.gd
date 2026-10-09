extends GutTest
## docs/03-data-formats.md section 12, M0 item 7 (03-D19).


func _check(name: String) -> CharacterNames.Problem:
	return CharacterNames.check(name, 2, 16)


func test_good_names_pass() -> void:
	var names: PackedStringArray = [
		"Steven",
		"Al",
		"Knight 01",
		"Ab Cd Ef",
		String.chr(0x529B) + String.chr(0x58EB),
		"Steven" + String.chr(0x738B),
		"abcdefghijklmnop",
	]
	for name: String in names:
		assert_eq(_check(name), CharacterNames.Problem.NONE, name)


func test_length_counts_characters_not_bytes() -> void:
	var sixteen_chinese: String = ""
	for index: int in 16:
		sixteen_chinese += String.chr(0x528D)
	assert_eq(_check(sixteen_chinese), CharacterNames.Problem.NONE)
	assert_eq(_check(sixteen_chinese + String.chr(0x528D)), CharacterNames.Problem.LENGTH)
	assert_eq(_check("A"), CharacterNames.Problem.LENGTH)
	assert_eq(_check("abcdefghijklmnopq"), CharacterNames.Problem.LENGTH)


func test_spaces_only_between_words() -> void:
	assert_eq(_check(" Steven"), CharacterNames.Problem.SPACES)
	assert_eq(_check("Steven "), CharacterNames.Problem.SPACES)
	assert_eq(_check("Ste  ven"), CharacterNames.Problem.SPACES)


func test_other_characters_are_refused() -> void:
	for name: String in ["Ste_ven", "Steven!", "St" + String.chr(0x0435) + "ven", "a" + String.chr(0x3042), "Tab\tName"]:
		assert_eq(_check(name), CharacterNames.Problem.CHARACTERS, name.c_escape())


func test_case_and_full_width_are_the_same_name() -> void:
	var full_width: String = ""
	for letter: String in "Steven":
		full_width += String.chr(letter.unicode_at(0) + CharacterNames.FULL_WIDTH_OFFSET)
	assert_eq(_check(full_width), CharacterNames.Problem.NONE)
	var taken: PackedStringArray = ["Steven"]
	assert_true(CharacterNames.is_taken("steven", taken))
	assert_true(CharacterNames.is_taken("STEVEN", taken))
	assert_true(CharacterNames.is_taken(full_width, taken))
	assert_true(CharacterNames.is_taken("Steven", PackedStringArray([full_width])))


func test_look_alike_names_are_the_same_name() -> void:
	var taken: PackedStringArray = ["Mary"]
	assert_true(CharacterNames.is_taken("rnary", taken), "rn looks like m")
	var cyrillic: String = String.chr(0x0405) + "teven"
	assert_true(CharacterNames.is_taken(cyrillic, PackedStringArray(["steven"])))


func test_different_names_are_free() -> void:
	var taken: PackedStringArray = ["Steven", "Mary"]
	assert_false(CharacterNames.is_taken("Stephen", taken))
	assert_false(CharacterNames.is_taken("Maria", taken))
	assert_false(CharacterNames.is_taken("Anyone", PackedStringArray()))
