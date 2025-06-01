--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 162,
	gfxwidth = 86,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 86,
	height = 162,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	ignorethrownnpcs = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	v.despawnTimer = 180
	
	if data.friend then
		v.y = v.y + (2 * data.friendDir)
		data.friendTimer = data.friendTimer + 1
		if data.friendTimer == 64 then
			data.friendDir = 0
			SFX.play("friend inside me.ogg")
		elseif data.friendTimer == 160 then
			data.friendDir = 1
		elseif data.friendTimer >= 224 then
			data.friend = nil
		end
	else
		data.friendTimer = 0
		data.friendDir = -1
	end
	
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			friend = data.friend,
			friendTimer = data.friendTimer,
			friendDir = data.friendDir,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.friend = receivedData.friend
		data.friendTimer = receivedData.friendTimer
		data.friendDir = receivedData.friendDir
	end,
}

--Gotta return the library table!
return sampleNPC