local blockRespawning = require("scripts/blockRespawning")
local battleGeneral = require("scripts/battleGeneral")

blockRespawning.defaultRespawnTime = 24*30

function onTick()
	if battleGeneral.mode == battleGeneral.gameMode.PHANTO then
		for _,v in ipairs(NPC.get(86)) do
			v:kill(9)
		end
	end
end