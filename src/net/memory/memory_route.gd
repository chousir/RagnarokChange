class_name MemoryRoute
extends RefCounted
## One direction of a memory link: where packets go, under which network
## conditions, and the per-channel state that keeps reliable channels in order
## (docs/02-networking.md sections 3.2 and 14).

var target: MemoryEndpoint
## Sender's peer id as the target sees it.
var source_peer: int
var profile: NetSimProfile
var stats: TransportStats = TransportStats.new()
var _last_arrival: PackedInt64Array = PackedInt64Array()
var _next_sequence: PackedInt64Array = PackedInt64Array()


func _init(route_target: MemoryEndpoint, peer: int, conditions: NetSimProfile) -> void:
	target = route_target
	source_peer = peer
	profile = conditions
	stats.rtt_ms = conditions.rtt_ms
	_last_arrival.resize(Protocol.CHANNEL_COUNT)
	_next_sequence.resize(Protocol.CHANNEL_COUNT)


## Arrival time of a packet sent now on channel, or -1 when it is lost.
func schedule(now: int, channel: int, rng: RandomNumberGenerator) -> int:
	var arrival: int = now + one_way_delay(rng)
	if channel == Protocol.CHANNEL_REALTIME:
		if profile.loss_per_10000 > 0 and rng.randi_range(0, 9999) < profile.loss_per_10000:
			return -1
		if not profile.reorder:
			arrival = maxi(arrival, _last_arrival[channel])
	else:
		# A lost reliable packet is sent again after a round trip, and every
		# packet behind it on the channel waits (head-of-line blocking).
		while profile.loss_per_10000 > 0 and rng.randi_range(0, 9999) < profile.loss_per_10000:
			arrival += maxi(profile.rtt_ms, 1)
		arrival = maxi(arrival, _last_arrival[channel])
	_last_arrival[channel] = maxi(_last_arrival[channel], arrival)
	return arrival


func next_sequence(channel: int) -> int:
	_next_sequence[channel] += 1
	return _next_sequence[channel]


## Time by which everything already sent on the reliable channels has arrived.
func reliable_drain_time(now: int) -> int:
	var drained: int = now + profile.rtt_ms / 2
	for channel: int in Protocol.CHANNEL_COUNT:
		if channel != Protocol.CHANNEL_REALTIME:
			drained = maxi(drained, _last_arrival[channel])
	return drained


func one_way_delay(rng: RandomNumberGenerator) -> int:
	var half_spread: float = profile.jitter_ms / 2.0
	var delay: float = profile.rtt_ms / 2.0
	if half_spread > 0.0:
		delay += rng.randf_range(-half_spread, half_spread)
	return maxi(roundi(delay), 0)
