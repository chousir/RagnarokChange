class_name DecodedPacket
extends RefCounted
## Result of decoding one packet: the messages, or why the packet was rejected.

var ok: bool = false
var error: String = ""
## Server tick from the packet header; -1 for packets from a client.
var tick: int = -1
var messages: Array[ProtocolMessage] = []


static func rejected(reason: String) -> DecodedPacket:
	var packet: DecodedPacket = DecodedPacket.new()
	packet.error = reason
	return packet
