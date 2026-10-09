class_name NetSimProfile
extends RefCounted
## Network conditions the memory transport simulates (docs/02-networking.md
## section 14, 02-D20).

var name: String
var rtt_ms: int = 0
## Spread of the round trip: each direction varies by up to half of it, so the
## round trip stays within rtt_ms plus or minus jitter_ms.
var jitter_ms: int = 0
## Chance per 10000 that a realtime packet is lost. A reliable packet is never
## lost; it arrives one round trip later instead and holds up the packets behind
## it, as a resend in ENet would.
var loss_per_10000: int = 0
## Whether realtime packets may arrive out of order.
var reorder: bool = false


static func make(profile_name: String, rtt: int, jitter: int, loss: int, allow_reorder: bool) -> NetSimProfile:
	var profile: NetSimProfile = NetSimProfile.new()
	profile.name = profile_name
	profile.rtt_ms = rtt
	profile.jitter_ms = jitter
	profile.loss_per_10000 = loss
	profile.reorder = allow_reorder
	return profile


## The named conditions from 02 section 14, or null for an unknown name.
static func named(profile_name: String) -> NetSimProfile:
	match profile_name:
		"local":
			return make("local", 0, 0, 0, false)
		"good":
			return make("good", 60, 5, 0, false)
		"normal":
			return make("normal", 120, 15, 100, false)
		"bad":
			return make("bad", 250, 40, 500, true)
	return null


static func names() -> PackedStringArray:
	return ["local", "good", "normal", "bad"]
