class_name AccountSave
extends RefCounted
## The account file (docs/03-data-formats.md section 8.2), version 1.

const VERSION := 1
const FIELDS: PackedStringArray = ["schema_version", "account_id", "username", "created_at", "last_login_at", "characters"]
const USERNAME_PATTERN := "^[A-Za-z0-9]{4,23}$"
const MAX_ID := 0x7FFFFFFF

static var _username_regex: RegEx


static func migrator() -> SaveMigrator:
	return SaveMigrator.new(VERSION, {})


## Account names are 4 to 23 letters or digits (docs/02 section 12.1).
static func is_valid_username(username: String) -> bool:
	if _username_regex == null:
		_username_regex = RegEx.create_from_string(USERNAME_PATTERN)
	return _username_regex.search(username) != null


static func to_dictionary(record: AccountRecord) -> Dictionary:
	var characters: Array = []
	for char_id: int in record.characters:
		characters.append(char_id)
	return {
		"schema_version": VERSION,
		"account_id": record.account_id,
		"username": record.username,
		"created_at": record.created_at,
		"last_login_at": record.last_login_at,
		"characters": characters,
	}


static func from_dictionary(data: Dictionary, errors: PackedStringArray) -> AccountRecord:
	var check: SaveChecker = SaveChecker.new()
	var context: String = "account"
	check.only_keys(data, FIELDS, context)
	if check.whole(data, "schema_version", VERSION, VERSION, context) != VERSION:
		errors.append_array(check.errors)
		return null
	var record: AccountRecord = AccountRecord.new()
	record.account_id = check.whole(data, "account_id", 1, MAX_ID, context)
	record.username = check.text(data, "username", 23, context)
	if not record.username.is_empty() and not is_valid_username(record.username):
		check.errors.append("%s.username must be 4 to 23 letters or digits" % context)
	record.created_at = check.time(data, "created_at", context)
	record.last_login_at = check.time(data, "last_login_at", context)
	record.characters = check.id_list(data, "characters", context)
	if not check.errors.is_empty():
		errors.append_array(check.errors)
		return null
	return record
