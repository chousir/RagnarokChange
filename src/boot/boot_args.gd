class_name BootArgs
extends RefCounted
## User arguments after "--" (docs/01-architecture.md section 5.1).

enum Mode { SINGLE_PLAYER, SERVER, CONNECT, VIEWER, SHOTS }

const KNOWN := ["server", "connect", "viewer", "shots", "shots-label", "netsim", "run-seconds", "data-dir", "capture"]

var mode: Mode = Mode.SINGLE_PLAYER
## Network conditions for single-player (02 section 14); "local" by default.
var netsim: String = "local"
var connect_address: String = ""
var shots_script: String = ""
## Extra name for the screenshot output folder, for example cold or warm.
var shots_label: String = ""
## Quit cleanly after this many seconds; 0 runs until closed. Used by the smoke run.
var run_seconds: float = 0.0
## Folder for saves and settings instead of the user folder, so test runs never
## touch the player's own (docs/03 section 9.1). Empty means the user folder.
var data_dir: String = ""
## PNG path to save the last frame to when --run-seconds ends, for self-checks.
var capture_path: String = ""
var errors: PackedStringArray = []


static func parse(arguments: PackedStringArray, dedicated_build: bool = false) -> BootArgs:
	var args: BootArgs = BootArgs.new()
	var modes: PackedStringArray = []
	if dedicated_build:
		modes.append("server")
		args.mode = Mode.SERVER
	for argument: String in arguments:
		if not argument.begins_with("--"):
			args.errors.append("unexpected argument %s" % argument)
			continue
		var key: String = argument.substr(2).get_slice("=", 0)
		var has_value: bool = argument.contains("=")
		var value: String = argument.substr(argument.find("=") + 1) if has_value else ""
		if not KNOWN.has(key):
			args.errors.append("unknown argument --%s" % key)
			continue
		match key:
			"server":
				modes.append(key)
				args.mode = Mode.SERVER
			"viewer":
				modes.append(key)
				args.mode = Mode.VIEWER
			"connect":
				modes.append(key)
				args.mode = Mode.CONNECT
				args.connect_address = value
				if value.is_empty():
					args.errors.append("--connect needs host:port")
			"shots":
				modes.append(key)
				args.mode = Mode.SHOTS
				args.shots_script = value
				if value.is_empty():
					args.errors.append("--shots needs a script name")
			"shots-label":
				args.shots_label = value
			"netsim":
				args.netsim = value
				if NetSimProfile.named(value) == null:
					args.errors.append("--netsim must be one of %s" % ", ".join(NetSimProfile.names()))
			"capture":
				args.capture_path = value
				if value.is_empty() or not value.ends_with(".png"):
					args.errors.append("--capture needs a .png path")
			"data-dir":
				args.data_dir = value
				if value.is_empty():
					args.errors.append("--data-dir needs a folder")
			"run-seconds":
				if not value.is_valid_float() or value.to_float() <= 0.0:
					args.errors.append("--run-seconds needs a positive number")
				else:
					args.run_seconds = value.to_float()
	if modes.size() > 1:
		args.errors.append("choose one mode, not %s" % ", ".join(modes))
	return args
