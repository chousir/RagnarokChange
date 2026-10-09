class_name SinglePlayer
extends RefCounted
## Builds single-player (docs/01-architecture.md section 5.2): a local server and
## a client joined by the memory transport, logged in to the local account. The
## same path as multiplayer, only the transport differs (01-D03).

const LOCAL_ACCOUNT := "local"
const LOCAL_CHAR_ID := 1
const DEFAULT_NAME_KEY := "ui.character.default_name"

var hub: MemoryHub
var server: GameServer
var client: GameClient
var accounts: MemoryAccountStore


## Builds everything; the client node is added under parent. The server clock is
## shared with the hub so time sync sees one machine.
func start(parent: Node, data: DataCatalog, clock: GameClock, netsim: NetSimProfile, character_name: String) -> void:
	hub = MemoryHub.new(clock, Time.get_ticks_usec())
	accounts = MemoryAccountStore.new()
	var account_id: int = accounts.add_account(LOCAL_ACCOUNT, "")
	var start_logic: MapLogic = MapLogic.read(data.rules().get_text("start_map"))
	var start: Transform3D = start_logic.spawn_transform(data.rules().get_text("start_point"))
	accounts.add_character(CharacterRecord.create_new(LOCAL_CHAR_ID, account_id, character_name, data, start))
	server = GameServer.new(hub.create_server(), clock, data, accounts)
	client = GameClient.new()
	client.name = "GameClient"
	client.setup(hub.connect_client(netsim), clock, data, LOCAL_ACCOUNT, "")
	parent.add_child(client)


## Runs the server's due ticks; the client updates in its own _process.
func advance() -> void:
	server.advance()


## Saves and closes everything. The client node belongs to its parent, which
## frees it.
func stop() -> void:
	if server != null:
		server.shutdown()
		server = null
	if hub != null:
		hub.close()
		hub = null
	client = null
