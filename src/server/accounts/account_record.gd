class_name AccountRecord
extends RefCounted
## An account as the server keeps it (docs/03-data-formats.md section 8.2).
## The password fields come with M9; single-player has none.

var account_id: int = 0
var username: String = ""
var created_at: String = ""
var last_login_at: String = ""
## Character ids in the order of the character selection screen.
var characters: PackedInt64Array = PackedInt64Array()
