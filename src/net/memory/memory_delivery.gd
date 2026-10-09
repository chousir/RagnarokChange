class_name MemoryDelivery
extends RefCounted
## Something on its way to a memory endpoint, due at arrival_ms.

var arrival_ms: int = 0
## Tie-breaker so deliveries due at the same time keep their sending order.
var order: int = 0
var type: TransportEvent.Type = TransportEvent.Type.PACKET
## Sender's peer id as the receiver sees it.
var peer_id: int = 0
var channel: int = -1
var data: PackedByteArray = PackedByteArray()
## Per-channel sequence number, used to keep only the newest realtime packet.
var sequence: int = 0
var reason: TransportEvent.Reason = TransportEvent.Reason.NONE


static func make(event_type: TransportEvent.Type, arrival: int, sending_order: int, peer: int) -> MemoryDelivery:
	var delivery: MemoryDelivery = MemoryDelivery.new()
	delivery.type = event_type
	delivery.arrival_ms = arrival
	delivery.order = sending_order
	delivery.peer_id = peer
	return delivery


func is_before(other: MemoryDelivery) -> bool:
	if arrival_ms != other.arrival_ms:
		return arrival_ms < other.arrival_ms
	return order < other.order
