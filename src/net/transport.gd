@abstract
class_name Transport
extends RefCounted
## The only way the server and the client exchange bytes (docs/02-networking.md
## section 3.1, 02-D01). The memory transport (single-player and tests) and the
## ENet transport (M9) implement it; the code above never knows which it has.

## Peer id of the server as a client sees it. Clients get ids from 2 up.
const SERVER_PEER := 1


## Sends one packet to a peer on a channel (Protocol.CHANNEL_*).
@abstract func send(peer_id: int, channel: int, data: PackedByteArray) -> void


## Returns what happened since the last call: connections, disconnections and packets.
@abstract func poll() -> Array[TransportEvent]


## Closes the connection after the packets already sent on reliable channels
## arrive. Both sides then get a DISCONNECTED event carrying the reason.
@abstract func disconnect_peer(peer_id: int, reason: TransportEvent.Reason) -> void


@abstract func peer_stats(peer_id: int) -> TransportStats
