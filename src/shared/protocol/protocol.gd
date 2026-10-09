class_name Protocol
extends RefCounted
## Protocol constants (docs/02-networking.md section 4). Every change to the
## message catalog must bump VERSION; a test records the catalog fingerprint of
## each version and fails when the catalog changes without a new version (02-D05).

const VERSION := 1

## Channels (02-D02).
const CHANNEL_CONTROL := 0  ## Reliable and ordered: handshake, commands, events.
const CHANNEL_REALTIME := 1  ## Unreliable, newest only: movement input, snapshots, time sync.
const CHANNEL_BULK := 2  ## Reliable and ordered: chat and large data.
const CHANNEL_COUNT := 3

## Packet size limits (02 sections 3.4 and 4.4).
const MAX_SERVER_REALTIME_PACKET := 1200
const MAX_SERVER_RELIABLE_PACKET := 65536
const MAX_CLIENT_REALTIME_PACKET := 512
const MAX_CLIENT_RELIABLE_PACKET := 4096

enum Direction { CLIENT_TO_SERVER, SERVER_TO_CLIENT }

## Message ids, grouped by range (02 section 4.2).
const HELLO := 0x0001
const HELLO_RESULT := 0x0002
const LOGIN := 0x0003
const LOGIN_RESULT := 0x0004
const SELECT_CHARACTER := 0x0005
const PING := 0x0006
const PONG := 0x0007
const MAP_CHANGE := 0x0101
const MAP_LOADED := 0x0102
const MAP_READY := 0x0103
const ENTITY_APPEAR := 0x0104
const ENTITY_VANISH := 0x0105
const SNAPSHOT := 0x0106

enum HelloStatus { OK, VERSION_MISMATCH, DATA_MISMATCH, SERVER_FULL, SERVER_CLOSING }
enum LoginStatus { OK, WRONG_PASSWORD, IP_BLOCKED }
enum Gender { FEMALE, MALE }
enum EntityKind { PLAYER, MONSTER, NPC, ITEM }
## Why an entity comes into view (02 section 9): it was already there, or it just
## spawned, respawned or arrived.
enum AppearReason { IN_PLACE, NEW }
## Why an entity leaves the view, as RO sorts them (02 section 9).
enum VanishReason { OUT_OF_SIGHT, DEAD, LOGOUT, TELEPORT, FEIGN_DEATH }


## Text key the client shows for a handshake result (docs/03 section 7).
static func hello_status_text(status: HelloStatus) -> String:
	match status:
		HelloStatus.VERSION_MISMATCH:
			return MessageIds.LOGIN_VERSION_MISMATCH
		HelloStatus.DATA_MISMATCH:
			return MessageIds.LOGIN_DATA_MISMATCH
		HelloStatus.SERVER_FULL:
			return MessageIds.LOGIN_SERVER_FULL
		HelloStatus.SERVER_CLOSING:
			return MessageIds.LOGIN_SERVER_CLOSING
	return ""


static func login_status_text(status: LoginStatus) -> String:
	match status:
		LoginStatus.WRONG_PASSWORD:
			return MessageIds.LOGIN_WRONG_PASSWORD
		LoginStatus.IP_BLOCKED:
			return MessageIds.LOGIN_IP_BLOCKED
	return ""


## Angles travel as u16: 0..65535 covers 0..360 degrees (02 section 4.1).
static func angle_to_u16(degrees: float) -> int:
	return roundi(fposmod(degrees, 360.0) / 360.0 * 65536.0) % 65536


static func u16_to_angle(value: int) -> float:
	return value * 360.0 / 65536.0


static func max_packet_size(direction: Direction, channel: int) -> int:
	var realtime: bool = channel == CHANNEL_REALTIME
	if direction == Direction.CLIENT_TO_SERVER:
		return MAX_CLIENT_REALTIME_PACKET if realtime else MAX_CLIENT_RELIABLE_PACKET
	return MAX_SERVER_REALTIME_PACKET if realtime else MAX_SERVER_RELIABLE_PACKET
