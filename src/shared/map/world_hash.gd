class_name WorldHash
extends RefCounted
## The game data hash both sides compare in the handshake (docs/02-networking.md
## section 4.3): the JSON data plus what the server reads from every map's
## logic scene, so a map changed on one side only is caught at login.


static func compute(catalog: DataCatalog) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(catalog.data_hash.to_utf8_buffer())
	for map_id: String in catalog.ids("maps"):
		context.update(MapLogic.read(map_id).content_hash().to_utf8_buffer())
	return context.finish().hex_encode()
