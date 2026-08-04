
local battleWario = require("scripts/custom/battleWario")

local hasInitialized = false

local costume = {}

costume.playersList = {}

function costume.onInit(p)
	-- If events have not been registered yet, do so
	if not hasInitialized then
		registerEvent(costume,"onTickEnd")
		battleWario.registerCostume(p:getCostume())
		hasInitialized = true
	end
	table.insert(costume.playersList,p)
end

function costume.onCleanup(p)
	local spot = table.ifind(costume.playersList,p)

	if spot ~= nil then
		table.remove(costume.playersList,spot)
	end
end

function costume.onTickEnd()
	-- because battle arena's costume system ignores held item offsets set in ini files, we'll adjust the held item manually.
	for _,p in ipairs(costume.playersList) do
		if p.holdingNPC and p.holdingNPC.isValid then
			local v = p.holdingNPC
			v.y = p.y + 12 - v.height
		end
	end
end


return costume
