class_name FileAccountStore
extends AccountStore
## Accounts and characters in save files (docs/03-data-formats.md section 8):
##   <root>/accounts/<account_id>.json
##   <root>/characters/<char_id>.json
##   <root>/counters.json
##   <root>/backup/
## A file that fails its checks is refused and left as it is (03-D20); the
## problems go to errors, so one broken save never stops the others.

const SIDE := "SV"
const LOCAL_ACCOUNT := "local"

var root: String
var catalog: DataCatalog
var writer: SaveWriter
## Problems found while opening or loading, for the log.
var errors: PackedStringArray = []
var warnings: PackedStringArray = []
## Why the last create_character() refused the name.
var last_name_problem: CharacterNames.Problem = CharacterNames.Problem.NONE

## account id -> AccountRecord
var _accounts: Dictionary = {}
## lower-case username -> account id
var _account_ids: Dictionary = {}
## char id -> name, for the uniqueness check (03-D19)
var _names: Dictionary = {}
var _next_account_id: int = 1
var _next_char_id: int = 1


func _init(save_root: String, data: DataCatalog, use_thread: bool = true) -> void:
	root = ProjectSettings.globalize_path(save_root)
	catalog = data
	writer = SaveWriter.new(use_thread)


## Reads every account and the names of every character.
func open() -> void:
	for path: String in _json_files("accounts"):
		var account: AccountRecord = _read_account(path)
		if account != null:
			_accounts[account.account_id] = account
			_account_ids[account.username.to_lower()] = account.account_id
			_next_account_id = maxi(_next_account_id, account.account_id + 1)
	for path: String in _json_files("characters"):
		var record: CharacterRecord = _read_character(path)
		if record != null:
			_names[record.char_id] = record.name
			_next_char_id = maxi(_next_char_id, record.char_id + 1)
	var counters: SaveRead = SaveFile.read(_counters_path())
	if counters.ok:
		var check: SaveChecker = SaveChecker.new()
		_next_account_id = maxi(_next_account_id, check.whole(counters.data, "next_account_id", 1, AccountSave.MAX_ID, "counters"))
		_next_char_id = maxi(_next_char_id, check.whole(counters.data, "next_char_id", 1, CharacterSave.MAX_ID, "counters"))
		warnings.append_array(check.errors)
	_log_problems()


## Waits for queued writes and stops the writer thread.
func close() -> void:
	writer.stop()
	for failure: String in writer.take_failures():
		Log.error(SIDE, "save", failure)


func flush() -> void:
	writer.flush()
	for failure: String in writer.take_failures():
		Log.error(SIDE, "save", failure)


## Single-player logs in to the local account without a password; real
## accounts and password hashes come with M9 (02-D18).
func authenticate(account: String, password: String) -> int:
	if account != LOCAL_ACCOUNT or not password.is_empty():
		return -1
	var account_id: int = _account_ids.get(LOCAL_ACCOUNT, -1)
	return account_id


func characters_of(account_id: int) -> Array[CharacterRecord]:
	var result: Array[CharacterRecord] = []
	var account: AccountRecord = _accounts.get(account_id)
	if account == null:
		return result
	for char_id: int in account.characters:
		var record: CharacterRecord = load_character(account_id, char_id)
		if record != null:
			result.append(record)
	return result


func load_character(account_id: int, char_id: int) -> CharacterRecord:
	var record: CharacterRecord = _read_character(_character_path(char_id))
	_log_problems()
	if record == null or record.account_id != account_id or record.char_id != char_id:
		return null
	return record


func save_character(record: CharacterRecord) -> bool:
	record.last_saved_at = SaveChecker.utc_now()
	writer.write(_character_path(record.char_id), SaveFile.to_text(CharacterSave.to_dictionary(record)))
	record.dirty = false
	_names[record.char_id] = record.name
	return true


func account_named(username: String) -> AccountRecord:
	var account_id: int = _account_ids.get(username.to_lower(), -1)
	var account: AccountRecord = _accounts.get(account_id)
	return account


func create_account(username: String) -> AccountRecord:
	if not AccountSave.is_valid_username(username) or _account_ids.has(username.to_lower()):
		return null
	var account: AccountRecord = AccountRecord.new()
	account.account_id = _next_account_id
	_next_account_id += 1
	account.username = username
	account.created_at = SaveChecker.utc_now()
	account.last_login_at = account.created_at
	_accounts[account.account_id] = account
	_account_ids[username.to_lower()] = account.account_id
	_write_account(account)
	_write_counters()
	return account


## Makes a new character with the default look at start (03 section 8.3).
## Returns null when the account is unknown or the name is not allowed; the
## reason is in last_name_problem.
func create_character(account_id: int, character_name: String, start: Transform3D) -> CharacterRecord:
	var account: AccountRecord = _accounts.get(account_id)
	var limits: PackedInt32Array = catalog.rules().get_int_pair("character_name_length")
	last_name_problem = CharacterNames.check(character_name, limits[0], limits[1])
	if last_name_problem == CharacterNames.Problem.NONE and CharacterNames.is_taken(character_name, PackedStringArray(_names.values())):
		last_name_problem = CharacterNames.Problem.TAKEN
	if account == null or last_name_problem != CharacterNames.Problem.NONE:
		return null
	var record: CharacterRecord = CharacterRecord.create_new(_next_char_id, account_id, character_name, catalog, start)
	_next_char_id += 1
	account.characters.append(record.char_id)
	save_character(record)
	_write_account(account)
	_write_counters()
	return record


func _read_account(path: String) -> AccountRecord:
	var data: Dictionary = _read_current(path, AccountSave.migrator())
	if data.is_empty():
		return null
	var problems: PackedStringArray = []
	var account: AccountRecord = AccountSave.from_dictionary(data, problems)
	for problem: String in problems:
		errors.append("%s: %s" % [path, problem])
	return account


func _read_character(path: String) -> CharacterRecord:
	var data: Dictionary = _read_current(path, CharacterSave.migrator())
	if data.is_empty():
		return null
	var problems: PackedStringArray = []
	var record: CharacterRecord = CharacterSave.from_dictionary(data, catalog, problems)
	for problem: String in problems:
		errors.append("%s: %s" % [path, problem])
	return record


## Reads a save and migrates it to the current version, backing up the old copy.
func _read_current(path: String, migrator: SaveMigrator) -> Dictionary:
	if not SaveFile.exists(path):
		return {}
	var read: SaveRead = SaveFile.read(path)
	warnings.append_array(read.warnings)
	if not read.ok:
		errors.append(read.error)
		return {}
	var problems: PackedStringArray = []
	if migrator.needs_migration(read.data):
		var version_value: float = read.data.get("schema_version", 0.0)
		var backup_problem: String = SaveMigrator.back_up(read.source, root.path_join("backup"), int(version_value))
		if not backup_problem.is_empty():
			errors.append(backup_problem)
			return {}
	var migrated: Dictionary = migrator.migrate(read.data, problems)
	for problem: String in problems:
		errors.append("%s: %s" % [path, problem])
	return migrated


func _write_account(account: AccountRecord) -> void:
	writer.write(_account_path(account.account_id), SaveFile.to_text(AccountSave.to_dictionary(account)))


func _write_counters() -> void:
	writer.write(_counters_path(), SaveFile.to_text({"next_account_id": _next_account_id, "next_char_id": _next_char_id}))


func _json_files(folder: String) -> PackedStringArray:
	var directory: String = root.path_join(folder)
	var files: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(directory):
		return files
	var seen: Dictionary = {}
	for file: String in DirAccess.get_files_at(directory):
		# x.json, x.json.tmp and x.json.bak are one save (03 section 8.5).
		var base: String = file.trim_suffix(SaveFile.TMP_SUFFIX).trim_suffix(SaveFile.BAK_SUFFIX)
		if base.ends_with(".json") and not seen.has(base):
			seen[base] = true
			files.append(directory.path_join(base))
	files.sort()
	return files


func _log_problems() -> void:
	for problem: String in errors:
		Log.error(SIDE, "save", problem)
	for warning: String in warnings:
		Log.warn(SIDE, "save", warning)
	errors.clear()
	warnings.clear()


func _account_path(account_id: int) -> String:
	return root.path_join("accounts/%d.json" % account_id)


func _character_path(char_id: int) -> String:
	return root.path_join("characters/%d.json" % char_id)


func _counters_path() -> String:
	return root.path_join("counters.json")
