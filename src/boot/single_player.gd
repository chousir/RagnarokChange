class_name SinglePlayer
extends RefCounted
## Builds single-player (docs/01-architecture.md section 5.2): a local server and
## a client joined by the memory transport, logged in to the local account. The
## same path as multiplayer, only the transport differs (01-D03).

const LOCAL_ACCOUNT := FileAccountStore.LOCAL_ACCOUNT
const DEFAULT_NAME_KEY := "ui.character.default_name"
const SAVE_ROOT := "user://saves"

var hub: MemoryHub
var server: GameServer
var client: GameClient
var accounts: FileAccountStore


## Builds everything; the client node is added under parent. The first start
## makes the local account and its character (03 section 8.3). Returns an empty
## string, or why single-player cannot start.
func start(parent: Node, data: DataCatalog, clock: GameClock, netsim: NetSimProfile, character_name: String, settings: ServerSettings, save_root: String = SAVE_ROOT) -> String:
	accounts = FileAccountStore.new(save_root, data)
	accounts.open()
	var problem: String = _ensure_local_character(data, character_name)
	if not problem.is_empty():
		accounts.close()
		return problem
	accounts.flush()
	hub = MemoryHub.new(clock, Time.get_ticks_usec())
	server = GameServer.new(hub.create_server(), clock, data, accounts)
	server.configure(settings)
	client = GameClient.new()
	client.name = "GameClient"
	client.setup(hub.connect_client(netsim), clock, data, LOCAL_ACCOUNT, "")
	parent.add_child(client)
	return ""


## Runs the server's due ticks; the client updates in its own _process.
func advance() -> void:
	server.advance()


## Saves and closes everything. The client node belongs to its parent, which
## frees it.
func stop() -> void:
	if server != null:
		server.shutdown()
		server = null
	elif accounts != null:
		accounts.close()
	if hub != null:
		hub.close()
		hub = null
	client = null


func _ensure_local_character(data: DataCatalog, character_name: String) -> String:
	var account: AccountRecord = accounts.account_named(LOCAL_ACCOUNT)
	if account == null:
		account = accounts.create_account(LOCAL_ACCOUNT)
		if account == null:
			return "cannot create the local account"
	if not account.characters.is_empty():
		if accounts.characters_of(account.account_id).is_empty():
			# Never overwrite a save that failed its checks (03-D20).
			return "the local character cannot be loaded; its save is kept as it is"
		return ""
	var rules: DataEntry = data.rules()
	var start: Transform3D = MapLogic.read(rules.get_text("start_map")).spawn_transform(rules.get_text("start_point"))
	if accounts.create_character(account.account_id, character_name, start) == null:
		return "cannot create the local character %s (%s)" % [character_name, CharacterNames.Problem.keys()[accounts.last_name_problem]]
	return ""
