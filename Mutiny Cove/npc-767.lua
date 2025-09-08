--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")
local npcutils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 196,
	gfxheight = 196,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 128,
	height = 192,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	speed = 0,
	nowaterphysics = true,

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	
	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	nowalldeath = true, -- If true, the NPC will not die when released in a wall
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
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
	or v.forcedState > 0--Various forced states
	then
		v.noblockcollision = true
	else
		v.speedX = 0
		if not data.top then
			v.y = Section(player.section).boundary.top
			data.top = true
			v.speedY = 8
		else
			
			for _,p in ipairs(Player.get()) do
				if not v.friendly and Colliders.collide(p, v) then
					p:harm()
				end
			end
			
			if not v.friendly then
				for _,p in ipairs(NPC.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
					if (p.id >= 754 and p.id <= 765) or (p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 and p.idx ~= v.idx and v:mem(0x12C, FIELD_WORD) == 0 and NPC.HITTABLE_MAP[p.id]) then
						p:harm(HARM_TYPE_HELD)
						if p.id >= 754 and p.id <= 765 then
							if p.data.state == 0 then
								SFX.play(NPC.config[p.id].sound)
								p.data.state = 1
							end
						end
					end
				end
			end
		
			v.noblockcollision = false
			if v.collidesBlockBottom then
				v.friendly = true
				data.timer = data.timer + 1
				if data.timer == 1 then SFX.play("SFX/Anchor.wav") end
				if data.timer >= 96 then
					v:kill(9)
				end
			end
		end
	end
end

function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data
	
	if not v.isHidden then
		npcutils.drawNPC(v,{priority = -55, opacity = 12 - ((data.timer or 0) * 0.125)})
	end
	npcutils.hideNPC(v)
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			timer = data.timer,
			top = data.top,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.timer = receivedData.timer
		data.top = receivedData.top
	end,
}

--Gotta return the library table!
return sampleNPC