extends Node
## Entry point: reads the user arguments and builds the chosen mode
## (docs/01-architecture.md section 5). Modes that arrive in later milestones
## say so and quit.

const SIDE := ""
## Frame cap when nothing is drawn, so a headless run does not spin a core.
const HEADLESS_MAX_FPS := 120
const USER_FOLDER := "user://"
## Development tool scene, loaded by path so game code never depends on tools/.
const SHOTS_SCENE := "res://tools/shots/shots_runner.tscn"

var _single_player: SinglePlayer = null
var _quit_at_ms: int = -1


func _ready() -> void:
	var args: BootArgs = BootArgs.parse(OS.get_cmdline_user_args(), OS.has_feature("dedicated_server"))
	if not args.errors.is_empty():
		for problem: String in args.errors:
			Log.error(SIDE, "boot", problem)
		_quit(2)
		return
	if not GameData.catalog.errors.is_empty():
		Log.error(SIDE, "boot", "game data has %d problems; see above" % GameData.catalog.errors.size())
		_quit(3)
		return
	if DisplayServer.get_name() == "headless":
		Engine.max_fps = HEADLESS_MAX_FPS
	if args.run_seconds > 0.0:
		_quit_at_ms = Time.get_ticks_msec() + roundi(args.run_seconds * 1000.0)
	match args.mode:
		BootArgs.Mode.SINGLE_PLAYER:
			_start_single_player(args)
		BootArgs.Mode.SERVER, BootArgs.Mode.CONNECT:
			Log.info(SIDE, "boot", "multiplayer needs the ENet transport, which arrives in M9")
			_quit(0)
		BootArgs.Mode.VIEWER:
			Log.info(SIDE, "boot", "the motion viewer arrives in M3")
			_quit(0)
		BootArgs.Mode.SHOTS:
			# The tool reads its own arguments; boot only hands over the scene.
			get_tree().change_scene_to_file.call_deferred(SHOTS_SCENE)


func _process(_delta: float) -> void:
	if _single_player != null:
		_single_player.advance()
	if _quit_at_ms >= 0 and Time.get_ticks_msec() >= _quit_at_ms:
		_quit_at_ms = -1
		_report_and_quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_stop()


func _start_single_player(args: BootArgs) -> void:
	var folder: String = args.data_dir if not args.data_dir.is_empty() else USER_FOLDER
	var server_settings: ServerSettings = ServerSettings.load_from(folder.path_join("server.cfg"), ServerSettings.process_environment())
	if not server_settings.errors.is_empty():
		for problem: String in server_settings.errors:
			Log.error(SIDE, "boot", problem)
		_quit(3)
		return
	var level: int = Log.Level.get(server_settings.get_text("log_level"), Log.Level.INFO)
	Log.min_level = level as Log.Level
	Log.info(SIDE, "boot", "server settings: %s" % server_settings.describe())
	var client_settings: ClientSettings = ClientSettings.load_from(folder.path_join("settings.cfg"))
	for warning: String in client_settings.warnings:
		Log.warn(SIDE, "settings", warning)
	InputActions.apply(client_settings.bindings)
	var locale: LocaleCatalog = LocaleCatalog.new()
	if not locale.load_from_dir("res://locale", GameData.catalog):
		for problem: String in locale.errors:
			Log.error(SIDE, "boot", problem)
		_quit(3)
		return
	locale.register()
	_single_player = SinglePlayer.new()
	var character_name: String = locale.display.get(SinglePlayer.DEFAULT_NAME_KEY, "Adventurer")
	var start_problem: String = _single_player.start(self, GameData.catalog, SystemClock.new(), NetSimProfile.named(args.netsim), character_name, server_settings, folder.path_join("saves"))
	if not start_problem.is_empty():
		Log.error(SIDE, "boot", start_problem)
		_single_player = null
		_quit(4)
		return
	Log.info(SIDE, "boot", "single-player started (netsim %s)" % args.netsim)


## Summary line read by tools/scripts/smoke.ps1.
func _report_and_quit() -> void:
	if _single_player != null:
		var server: GameServer = _single_player.server
		var client: GameClient = _single_player.client
		Log.info(SIDE, "boot", "smoke: ticks=%d snapshots_sent=%d snapshots_received=%d in_game=%s map=%s max_tick_ms=%.2f skipped_ms=%d" % [
			server.tick, server.snapshots_sent, client.snapshots_received, client.is_in_game(), client.map_id,
			server.max_tick_usec / 1000.0, server.skipped_ms,
		])
	_quit(0)


func _stop() -> void:
	if _single_player != null:
		_single_player.stop()
		_single_player = null


func _quit(code: int) -> void:
	_stop()
	get_tree().quit(code)
