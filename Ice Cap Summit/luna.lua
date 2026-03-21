local onlinePlay = require("scripts/onlinePlay")

local thing = onlinePlay.createVariable("thing","uint16",true,0)

local sectionMusic = {
	"Ice Cap Summit/12 - IceCap Zone Act 2.vgm|0;g=2.25;e0",
	"Ice Cap Summit/12 - IceCap Zone Act 2.vgm|0;g=2.25;e0",
	"Ice Cap Summit/12 - IceCap Zone Act 2.vgm|0;g=2.25;e0",
	"Ice Cap Summit/12 - IceCap Zone Act 2.vgm|0;g=2.25;e0",
	"Ice Cap Summit/12 - IceCap Zone Act 2.vgm|0;g=2.25;e0",
	"Ice Cap Summit/12 - IceCap Zone Act 2.vgm|0;g=2.25;e0",
	"Ice Cap Summit/12 - IceCap Zone Act 2.vgm|0;g=2.25;e0",
	"Ice Cap Summit/12 - IceCap Zone Act 2.vgm|0;g=2.25;e0",
	"Ice Cap Summit/12 - IceCap Zone Act 2.vgm|0;g=2.25;e0",
	"Ice Cap Summit/Hard Times - The Jetzons.ogg"
} 

function onDraw()
	--Load the level into the game
	if not Misc.isPaused() then
		thing.value = thing.value + 1
		if onlinePlay.currentMode == onlinePlay.MODE_CLIENT then
			if thing.value == 2 then
				Audio.MusicChange(0, sectionMusic[RNG.randomInt(1,10)])
			end
		else
			if thing.value == 1 then
				Audio.MusicChange(0, sectionMusic[RNG.randomInt(1,10)])
			end
		end
	end
end
		