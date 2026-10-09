class_name TransportStats
extends RefCounted
## Connection numbers for the debug panel (docs/02-networking.md section 14).

var rtt_ms: int = 0
var packets_sent: int = 0
var packets_received: int = 0
var packets_lost: int = 0
var bytes_sent: int = 0
var bytes_received: int = 0


func loss_pct() -> float:
	if packets_sent == 0:
		return 0.0
	return packets_lost * 100.0 / packets_sent
