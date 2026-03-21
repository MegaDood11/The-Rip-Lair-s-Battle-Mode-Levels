local onlinePlay = require("scripts/onlinePlay")

local timer = 0
local lastSong
local audioValue

local audioList = {
	"12TH_STREET_RAG_WITH BASS_SG_JW_NC.ogg",
	"A Pineapple Luau.ogg",
	"bungebob.ogg",
	"CLOSING_THEME_SB.ogg",
	"Coconut Cream Pie (Dry).ogg",
	"Electric Zoo.ogg",
	"Gary Come Home.ogg",
	"Goofy Goober Rock.ogg",
	"GRASS_SKIRT_CHASE_SG_JW.ogg",
	"HAWAIIAN_MISADVENTURES_SG_JW.ogg",
	"Ocean Man.ogg",
	"SLIDE_WHISTLE_STOOGES_NC_SG_JW.ogg",
	"Squidward's Tiki Land (Instrumental).ogg",
	"Sweet Victory.ogg",
	"The Drunken Sailor.ogg",
	"This Grill is Not a Home.ogg",
	"When Worlds Collide.ogg",
	"In Bloom (Spongebob Edition).ogg",
	"The Athletic.ogg",
	"The Rake Hornpipe.ogg",
	"Tomfoolery.ogg",
	"Aloha.ogg",
	"Bell Hop (a).ogg",
	"The Lineman.ogg",
	"The Bottom 2.ogg"
}

local audioLength = {45, 65, 165, 83, 69, 15.5, 81, 170.5, 31, 26, 125, 87, 110, 226, 30, 72, 75, 43, 43, 68, 126, 29, 157, 156, 163}

function onDraw()
	if not audioValue then
		audioValue = RNG.randomInt(0, 24)
		if not lastSong then
			Audio.MusicChange(0, "Bikini Bottom/Music List/" .. audioList[audioValue + 1])
			timer = audioLength[audioValue + 1]
			lastSong = audioValue
		else
			if lastSong ~= audioValue then
				lastSong = nil
			end
		end
	else
		if Audio.MusicClock() >= timer then
			audioValue = nil
		end
	end
end


-- Run code on level start
function onStart()
    --Your code here
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Heroes"):show(true)
	end
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Spongebob"):show(true)
	end	
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Patrick"):show(true)
	end	
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Squidward"):show(true)
	end
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Sandy"):show(true)
	end
end