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

	-- ANIMATION
	--Sprite size
	gfxwidth = 38,
	gfxheight = 62,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 24,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 10,
	nowaterphysics = true,

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	noiceball = true,
	noyoshi = true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = false,

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = true,

	grabside=false,
	grabtop=false,
	ishot = true,
	durability = 1, -- Durability for elemental interactions like ishot and iscold. -1 = infinite durability
	
	--Emits light if the Darkness feature is active:
	lightradius = 80,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.orange,
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
		v.ai1 = 1
	end

	--Control animation and when it should die
	v.ai1 = v.ai1 + 1
	v.animationFrame = math.floor(v.ai1 / 4) % sampleNPCSettings.frames
	
	if v.ai1 >= 40 then
		v:kill(HARM_TYPE_OFFSCREEN)
	end
	
	if not v.collidesBlockBottom then v:kill(9) end
	
	--Control when it should be harmful
	if v.animationFrame > 2 and v.animationFrame <= 7 then
		v.friendly = true
		
		for _,n in ipairs(NPC.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
			if (n.id >= 754 and n.id <= 765) then
				if n.data.state == 0 then
					SFX.play(NPC.config[n.id].sound)
					n.data.state = 1
					n.ai2 = 1
					n.speedX = 4 * v.direction
					n.speedY = -5
					n.ai3 = 5
				end
			end
		end
		
	else
		v.friendly = false
	end
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			stayDir = data.stayDir,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.stayDir = receivedData.stayDir
	end,
}

--Gotta return the library table!
return sampleNPC