class_name TransportEvent
extends RefCounted
## Something a transport reports: a connection, a disconnection or a packet.

enum Type { CONNECTED, DISCONNECTED, PACKET }
## Why a connection closed.
enum Reason { NONE, CLOSED, TIMEOUT, REJECTED, VIOLATIONS, KICKED, SHUTDOWN }

var type: Type
var peer_id: int
var channel: int = -1
var data: PackedByteArray = PackedByteArray()
var reason: Reason = Reason.NONE
## How long ago the packet arrived, in ms. Packets are read once per tick or
## frame; time sync uses this to stamp the real arrival (02 section 6).
var age_ms: int = 0


static func connected(peer: int) -> TransportEvent:
	var event: TransportEvent = TransportEvent.new()
	event.type = Type.CONNECTED
	event.peer_id = peer
	return event


static func disconnected(peer: int, why: Reason) -> TransportEvent:
	var event: TransportEvent = TransportEvent.new()
	event.type = Type.DISCONNECTED
	event.peer_id = peer
	event.reason = why
	return event


static func packet(peer: int, packet_channel: int, bytes: PackedByteArray, age: int) -> TransportEvent:
	var event: TransportEvent = TransportEvent.new()
	event.type = Type.PACKET
	event.peer_id = peer
	event.channel = packet_channel
	event.data = bytes
	event.age_ms = age
	return event
