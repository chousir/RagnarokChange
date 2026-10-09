extends GutTest
## Accounts and characters in save files (docs/03-data-formats.md section 8).

var _root: String = ""
var _store: FileAccountStore = null


func before_each() -> void:
	_root = GuardSamples.make_root("accounts")
	Log.begin_capture()


func after_each() -> void:
	if _store != null:
		_store.close()
		_store = null
	Log.end_capture()
	GuardSamples.remove_tree(_root)


func _open() -> FileAccountStore:
	if _store != null:
		_store.close()
	_store = FileAccountStore.new(_root, GameData.catalog, false)
	_store.open()
	return _store


func _start() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(1, 0, -2))


func test_local_account_and_character_survive_a_restart() -> void:
	var store: FileAccountStore = _open()
	var account: AccountRecord = store.create_account(FileAccountStore.LOCAL_ACCOUNT)
	var record: CharacterRecord = store.create_character(account.account_id, "Steven", _start())
	assert_not_null(record)
	assert_true(FileAccess.file_exists(_root.path_join("accounts/1.json")))
	assert_true(FileAccess.file_exists(_root.path_join("characters/1.json")))
	assert_true(FileAccess.file_exists(_root.path_join("counters.json")))
	store = _open()
	var account_id: int = store.authenticate(FileAccountStore.LOCAL_ACCOUNT, "")
	assert_eq(account_id, 1)
	var characters: Array[CharacterRecord] = store.characters_of(account_id)
	assert_eq(characters.size(), 1)
	assert_eq(characters[0].name, "Steven")
	assert_eq(characters[0].position, Vector3(1, 0, -2))
	assert_eq(characters[0].hair_style, "hair_twin_tails")


func test_only_the_local_account_without_password_logs_in() -> void:
	var store: FileAccountStore = _open()
	store.create_account(FileAccountStore.LOCAL_ACCOUNT)
	store.create_account("Steven2026")
	assert_eq(store.authenticate(FileAccountStore.LOCAL_ACCOUNT, "guess"), -1)
	assert_eq(store.authenticate("Steven2026", ""), -1, "passwords arrive in M9")


func test_names_are_unique_across_the_server() -> void:
	var store: FileAccountStore = _open()
	var first: AccountRecord = store.create_account("first")
	var second: AccountRecord = store.create_account("second")
	assert_not_null(store.create_character(first.account_id, "Steven", _start()))
	assert_null(store.create_character(second.account_id, "steven", _start()))
	assert_eq(store.last_name_problem, CharacterNames.Problem.TAKEN)
	assert_null(store.create_character(second.account_id, "S", _start()))
	assert_eq(store.last_name_problem, CharacterNames.Problem.LENGTH)
	store = _open()
	assert_null(store.create_character(second.account_id, "STEVEN", _start()), "names are known after a restart")


func test_ids_keep_counting_when_counters_are_lost() -> void:
	var store: FileAccountStore = _open()
	var account: AccountRecord = store.create_account(FileAccountStore.LOCAL_ACCOUNT)
	store.create_character(account.account_id, "Alpha", _start())
	store.create_character(account.account_id, "Bravo", _start())
	store.close()
	_store = null
	DirAccess.remove_absolute(_root.path_join("counters.json"))
	DirAccess.remove_absolute(_root.path_join("counters.json.bak"))
	store = _open()
	var third: CharacterRecord = store.create_character(account.account_id, "Charlie", _start())
	assert_eq(third.char_id, 3)


func test_broken_character_is_refused_and_left_untouched() -> void:
	var store: FileAccountStore = _open()
	var account: AccountRecord = store.create_account(FileAccountStore.LOCAL_ACCOUNT)
	store.create_character(account.account_id, "Steven", _start())
	store.close()
	_store = null
	var path: String = _root.path_join("characters/1.json")
	var text: String = FileAccess.get_file_as_string(path).replace("\"novice\"", "\"dragon_knight\"")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	store = _open()
	assert_null(store.load_character(account.account_id, 1))
	assert_string_contains("\n".join(Log.captured), "dragon_knight is not an id in jobs")
	assert_eq(FileAccess.get_file_as_string(path), text, "the file is not changed")


func test_newer_save_is_refused_and_left_untouched() -> void:
	var store: FileAccountStore = _open()
	var account: AccountRecord = store.create_account(FileAccountStore.LOCAL_ACCOUNT)
	store.create_character(account.account_id, "Steven", _start())
	store.close()
	_store = null
	var path: String = _root.path_join("characters/1.json")
	var text: String = FileAccess.get_file_as_string(path).replace("\"schema_version\": 1", "\"schema_version\": 99")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	store = _open()
	assert_null(store.load_character(account.account_id, 1))
	assert_string_contains("\n".join(Log.captured), "newer than this program")
	assert_eq(FileAccess.get_file_as_string(path), text)


func test_saving_marks_the_record_clean() -> void:
	var store: FileAccountStore = _open()
	var account: AccountRecord = store.create_account(FileAccountStore.LOCAL_ACCOUNT)
	var record: CharacterRecord = store.create_character(account.account_id, "Steven", _start())
	record.position = Vector3(5, 0, 5)
	record.dirty = true
	store.save_character(record)
	assert_false(record.dirty)
	assert_eq(store.load_character(account.account_id, record.char_id).position, Vector3(5, 0, 5))
