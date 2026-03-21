local blockRespawning = require("scripts/blockRespawning")

blockRespawning.defaultRespawnTime = 32*32

function onTick()
	for _,v in ipairs(Block.get(4)) do
		v.layerName = "Bricks"
	end
end