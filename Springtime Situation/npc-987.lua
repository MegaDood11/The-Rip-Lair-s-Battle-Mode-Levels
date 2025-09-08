--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 18,
	gfxheight = 10,
	width = 16,
	height = 8,
	frames = 2,
	framestyle = 1,
	framespeed = 8, 
	
	speed = 1,
	nohurt=true, -- Disables the NPC dealing contact damage to the player
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = true,
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall
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
		v.ai3 = 1
		data.jumpTable = {6, 6, 9}
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
	
	v.ai2 = v.ai2 + 1
	
	if v.collidesBlockBottom then
	
		v.animationFrame = 0 + (v.direction + 1)
		
		if math.abs(v.speedX) <= 0.25 then
			v.speedX = 0
		else
			v.speedX = v.speedX - 0.25 * v.direction
		end
		
		if v.ai2 >= 32 then
			--Jump away from players
			for _,p in ipairs(Player.get()) do
				if p.x > v.x then v.direction = -1 else v.direction = 1 end
			end
			--Speed
			v.speedX = 2.5 * v.direction
			--Follow the table defined in the Initialize section, and when the table ends go back to the first value
			v.speedY = -data.jumpTable[v.ai3]
			v.ai3 = v.ai3 + 1
			if v.ai3 > #data.jumpTable then v.ai3 = 1 end
		end
	else
		v.ai2 = 0
		v.animationFrame = 1 + (v.direction + 1)
	end
	
	--If underwater, bob up and try to escape the water source
	if v.underwater and v.speedY > -3.5 then
		v.speedY = v.speedY - 0.5
		if math.abs(v.speedX) <= 0.5 then
			v.speedX = 2.5 * v.direction
		end
	end
		
	
end

--Gotta return the library table!
return sampleNPC