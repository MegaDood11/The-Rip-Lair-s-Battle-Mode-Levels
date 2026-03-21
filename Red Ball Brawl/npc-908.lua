--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 96,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 96,
	height = 32,
	
	frames = 1,
	
	--Collision-related
	npcblock = true, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = true, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = true, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	
	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	
	
	
	
	
	spring_sound = "funnyspringsound.mp3", --Edit this Kurt, for example replace the number with "soundEffect.ogg" or something -- Gotcha :)
	spring_height = 19, -- How high should the player bounce? -- Send him to the stratosphere
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		-- Handling of those special states. Most NPCs want to not execute their main code when held/coming out of a block/etc.
		-- If that applies to your NPC, simply return here.
		-- return
	end
	
	for _,p in ipairs(Player.get()) do
		if (p.standingNPC ~= nil and p.standingNPC.idx == v.idx) and data.timer == 0 then
			SFX.play(sampleNPCSettings.spring_sound)
			data.timer = 1
		end
		
		if data.timer > 0 then
			data.timer = data.timer + 1
			if data.timer <= 12 then
				v.y = v.y - 5
				if data.timer >= 8 and math.abs(p.y - v.y) <= 64 and math.abs(p.x - v.x) <= 96 then
					p.speedY = -sampleNPCSettings.spring_height
				end
			else
				v.y = v.y + 2.5
				if v.y >= v.spawnY then
					data.timer = 0
				end
			end
		end
	end
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			timer = data.timer,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end
		data.timer = receivedData.timer
	end,
}

--Gotta return the library table!
return sampleNPC