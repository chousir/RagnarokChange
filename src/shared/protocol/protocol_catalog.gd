class_name ProtocolCatalog
extends RefCounted
## The message catalog, the single source for encoding, decoding and validation
## (02-D04, docs/02-networking.md section 4.5). Milestones add messages here;
## every change needs a new Protocol.VERSION.

## Longest name in bytes: 16 characters of up to 4 UTF-8 bytes each (03-D19).
const NAME_BYTES := 64
## RO allows up to 15 characters per account (rAthena MAX_CHARS).
const MAX_CHARACTERS := 15
## Entities per snapshot so a packet stays under 1,200 bytes (02 section 3.4).
const MAX_SNAPSHOT_ENTITIES := 56

static var _specs: Array[MessageSpec] = []
static var _by_id: Dictionary = {}


static func all() -> Array[MessageSpec]:
	if _specs.is_empty():
		_specs = _build()
		for spec: MessageSpec in _specs:
			_by_id[spec.id] = spec
	return _specs


## The message with this id, or null.
static func find(message_id: int) -> MessageSpec:
	all()
	if not _by_id.has(message_id):
		return null
	var spec: MessageSpec = _by_id[message_id]
	return spec


## SHA-256 of the whole catalog in id order (02 section 4.3).
static func fingerprint() -> String:
	var lines: PackedStringArray = []
	var specs: Array[MessageSpec] = all().duplicate()
	specs.sort_custom(func(a: MessageSpec, b: MessageSpec) -> bool: return a.id < b.id)
	for spec: MessageSpec in specs:
		lines.append(spec.describe())
	return "\n".join(lines).sha256_text()


static func _build() -> Array[MessageSpec]:
	var c2s: Protocol.Direction = Protocol.Direction.CLIENT_TO_SERVER
	var s2c: Protocol.Direction = Protocol.Direction.SERVER_TO_CLIENT
	var control: int = Protocol.CHANNEL_CONTROL
	var realtime: int = Protocol.CHANNEL_REALTIME
	return [
		MessageSpec.make(Protocol.HELLO, "Hello", c2s, control, "M0", [
			_u16("protocol_version"),
			_text("data_hash", 64),
		]),
		MessageSpec.make(Protocol.HELLO_RESULT, "HelloResult", s2c, control, "M0", [
			_u8("status").enum_of(Protocol.HelloStatus.size()),
			_u8("tick_rate").between(1, 120),
			_u8("snapshot_rate").between(1, 120),
		]),
		MessageSpec.make(Protocol.LOGIN, "Login", c2s, control, "M0", [
			_text("account", 64),
			_text("password", 256),
		]),
		MessageSpec.make(Protocol.LOGIN_RESULT, "LoginResult", s2c, control, "M0", [
			_u8("status").enum_of(Protocol.LoginStatus.size()),
			FieldSpec.of("characters", FieldSpec.Type.LIST).up_to(MAX_CHARACTERS).with_items([
				_u32("char_id"),
				_text("name", NAME_BYTES),
				_u16("job"),
			]),
		]),
		MessageSpec.make(Protocol.SELECT_CHARACTER, "SelectCharacter", c2s, control, "M0", [
			_u32("char_id"),
		]),
		MessageSpec.make(Protocol.PING, "Ping", c2s, realtime, "M0", [
			_u64("client_time"),
		]).limited_to(10),
		MessageSpec.make(Protocol.PONG, "Pong", s2c, realtime, "M0", [
			_u64("client_time"),
			_u64("server_time"),
		]),
		MessageSpec.make(Protocol.MAP_CHANGE, "MapChange", s2c, control, "M0", [
			_u16("map"),
			_f32("x"),
			_f32("y"),
			_f32("z"),
			_angle("facing"),
			_u16("move_epoch"),
			_u32("entity_id"),
			_u8("gender").enum_of(Protocol.Gender.size()),
			_u16("job"),
			_u16("hair_style"),
			_u16("hair_color"),
			_u16("eye_color"),
		]),
		MessageSpec.make(Protocol.MAP_LOADED, "MapLoaded", c2s, control, "M0", [
			_u16("map"),
		]),
		MessageSpec.make(Protocol.MAP_READY, "MapReady", s2c, control, "M0", []),
		MessageSpec.make(Protocol.ENTITY_APPEAR, "EntityAppear", s2c, control, "M0", [
			_u32("entity_id"),
			_u8("kind").enum_of(Protocol.EntityKind.size()),
			_u8("reason").enum_of(Protocol.AppearReason.size()),
			_u16("type"),
			_text("name", NAME_BYTES),
			_u8("gender").enum_of(Protocol.Gender.size()),
			_u16("hair_style"),
			_u16("hair_color"),
			_u16("eye_color"),
			_f32("x"),
			_f32("y"),
			_f32("z"),
			_angle("facing"),
			_f32("walk_speed"),
			_u8("flags"),
		]),
		MessageSpec.make(Protocol.ENTITY_VANISH, "EntityVanish", s2c, control, "M0", [
			_u32("entity_id"),
			_u8("reason").enum_of(Protocol.VanishReason.size()),
		]),
		MessageSpec.make(Protocol.SNAPSHOT, "Snapshot", s2c, realtime, "M0", [
			_u64("server_time"),
			_u32("base_tick"),
			_u32("input_seq"),
			_u16("move_epoch"),
			_f32("x"),
			_f32("y"),
			_f32("z"),
			_angle("facing"),
			FieldSpec.of("entities", FieldSpec.Type.LIST).up_to(MAX_SNAPSHOT_ENTITIES).with_items([
				_u32("entity_id"),
				_u8("changed"),
				_f32("x"),
				_f32("y"),
				_f32("z"),
				_angle("facing"),
				_u8("move_state"),
			]),
		]),
	]


static func _u8(field_name: String) -> FieldSpec:
	return FieldSpec.of(field_name, FieldSpec.Type.U8)


static func _u16(field_name: String) -> FieldSpec:
	return FieldSpec.of(field_name, FieldSpec.Type.U16)


static func _u32(field_name: String) -> FieldSpec:
	return FieldSpec.of(field_name, FieldSpec.Type.U32)


static func _u64(field_name: String) -> FieldSpec:
	return FieldSpec.of(field_name, FieldSpec.Type.U64)


static func _f32(field_name: String) -> FieldSpec:
	return FieldSpec.of(field_name, FieldSpec.Type.F32)


static func _angle(field_name: String) -> FieldSpec:
	return FieldSpec.of(field_name, FieldSpec.Type.ANGLE)


static func _text(field_name: String, max_bytes: int) -> FieldSpec:
	return FieldSpec.of(field_name, FieldSpec.Type.STRING).up_to(max_bytes)
