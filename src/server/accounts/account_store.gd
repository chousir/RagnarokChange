@abstract
class_name AccountStore
extends RefCounted
## Where the server finds accounts and characters. The in-memory store serves
## tests; the save files come with M0-e (docs/03-data-formats.md section 8).


## Checks an account and password. Returns the account id, or -1 when refused.
@abstract func authenticate(account: String, password: String) -> int


## Characters of an account, for LoginResult.
@abstract func characters_of(account_id: int) -> Array[CharacterRecord]


## One character of an account, or null.
@abstract func load_character(account_id: int, char_id: int) -> CharacterRecord


## Stores the character's current state.
@abstract func save_character(record: CharacterRecord) -> bool


## Finishes pending writes; the server calls it when it shuts down.
func close() -> void:
	pass
