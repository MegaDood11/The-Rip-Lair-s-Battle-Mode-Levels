local onlinePlay = require("scripts/onlinePlay")

local parallax = require("paralx2")

local bg

function onLoadSection()
	local p = parallax.get(player.section)
	if p then
		bg = p:get()
	end
end

function onTick()
	if bg then
		for k,v in ipairs(bg) do
			if v.name == "Pirate Ship" then
				v.speedY = math.sin(lunatime.tick() / 5) * 0.25
			end
		end
	end
end