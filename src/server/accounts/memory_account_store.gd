class_name MemoryAccountStore
extends AccountStore
## Accounts and characters kept in memory, for tests and until M0-e adds saves.

## account name -> {"id": int, "password": String}
var _accounts: Dictionary = {}
## char id -> CharacterRecord
var _characters: Dictionary = {}
var _next_account_id: int = 1


func add_account(account: String, password: String) -> int:
	var account_id: int = _next_account_id
	_next_account_id += 1
	_accounts[account] = {"id": account_id, "password": password}
	return account_id


func add_character(record: CharacterRecord) -> void:
	_characters[record.char_id] = record


func authenticate(account: String, password: String) -> int:
	if not _accounts.has(account):
		return -1
	var entry: Dictionary = _accounts[account]
	if str(entry["password"]) != password:
		return -1
	var account_id: int = entry["id"]
	return account_id


func characters_of(account_id: int) -> Array[CharacterRecord]:
	var result: Array[CharacterRecord] = []
	for char_id: int in _characters:
		var record: CharacterRecord = _characters[char_id]
		if record.account_id == account_id:
			result.append(record)
	return result


func load_character(account_id: int, char_id: int) -> CharacterRecord:
	var record: CharacterRecord = _characters.get(char_id)
	if record == null or record.account_id != account_id:
		return null
	return record


func save_character(record: CharacterRecord) -> bool:
	_characters[record.char_id] = record
	return true
