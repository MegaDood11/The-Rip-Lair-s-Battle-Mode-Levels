--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local spring = {}
local sonicspring = Misc.resolveFile("sonicspring.wav")
local utils = require("npcs/npcutils")

--Register events
function spring.register(npcID)
	npcManager.registerEvent(npcID, spring, "onTickEndNPC")
	--npcManager.registerEvent(npcID, spring, "onTickEndNPC")
	npcManager.registerEvent(npcID, spring, "onDrawNPC")
	--registerEvent(spring, "onNPCKill")
end

function spring.onTickEndNPC(v)
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
		v.ai1 = 0
		v.ai2 = 0
		data.ground = NPC.config[v.id].ground
		data.ceiling = NPC.config[v.id].ceiling
		data.wall = NPC.config[v.id].wall
		data.bounceforce = NPC.config[v.id].bounceforce
		
		--Only enable collision if needed
		if data.ground then
			data.springhitboxtop = Colliders.Tri(v.x + 32, v.y + (v.height / 2) - 2, {30,-16}, {0,14}, {-30, -16});
			--data.springhitboxtop:Debug(true);
		end
		if data.ceiling then
			data.springhitboxbottom = Colliders.Tri(v.x + 32, v.y + (v.height / 2) + 2, {30,16}, {0,-14}, {-30, 16});
			--data.springhitboxbottom:Debug(true);
		end
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	
	--Only enable collision if needed
	for _,p in ipairs(Player.get()) do
		if data.ground then
			if Colliders.collide(p, data.springhitboxtop) then
				p.speedY = -data.bounceforce
				v.ai1 = 1
				SFX.play(sonicspring)
			end
		end
		
		if data.ceiling then
			if Colliders.collide(p, data.springhitboxbottom) then
				p.speedY = data.bounceforce
				v.ai1 = 1
				SFX.play(sonicspring)
			end
		end
	end
	
	if v.ai1 == 1 then
		v.ai2 = v.ai2 + 1
	end
	
	if v.ai2 == 14 then
		v.ai1 = 0
		v.ai2 = 0
	end
end

function spring.onDrawNPC(v)	
	still = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 3,
		offset = 0
	})
	
	bounce = utils.getFrameByFramestyle(v, {
		frames = 3,
		gap = 0,
		offset = 1
	})
	
	if v.ai1 == 1 then
		utils.restoreAnimation(v)
		v.animationFrame = bounce
	else
		v.animationFrame = still
	end
end

--Gotta return the library table!
return spring