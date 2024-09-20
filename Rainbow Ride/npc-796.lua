--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local colliders = require("colliders")

--Create the library table
local flaptor = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local flaptorSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 48,
	speed = 1,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 42,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 8, 

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	activeradius = 8
}

--Applies NPC settings
npcManager.setNpcSettings(flaptorSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

local STATE_FLY = 0
local STATE_DROP = 1
local STATE_RETURN = 2

--Register events
function flaptor.onInitAPI()
	npcManager.registerEvent(npcID, flaptor, "onTickEndNPC")
end

function flaptor.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local plr = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		data.flyTimer = data.flyTimer or 0
		data.activeradius = flaptorSettings.activeradius or 8
		data.state = STATE_FLY
	end
	
	if settings.time == nil then
		settings.time = 192
	end
	
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		v.spawnY = v.y
	end
	
	if data.state == STATE_FLY then
		v.speedY = 0
		v.speedX = flaptorSettings.speed * v.direction
		v.animationFrame = math.floor(data.timer / 8) % 2
		--Timer start
		data.timer = data.timer + 1
		data.flyTimer = data.flyTimer + 1
		if data.flyTimer >= settings.time then
			v.direction = -v.direction
			data.flyTimer = 0
		end
		--If right under a player then drop down
		if math.abs(plr.x-v.x) <= data.activeradius and plr.y > v.y then
			data.timer = 0
			data.state = STATE_DROP
		end
	elseif data.state == STATE_DROP then
		data.timer = data.timer + 1
		if data.timer <= 16 then
			v.speedX = 0
			v.animationFrame = 2
		else
			v.animationFrame = 3
			v.speedY = 7
		end
		--Return up if it touches the ground
		if v.collidesBlockBottom then
		data.destroyCollider = data.destroyCollider or colliders.Box(v.x - 1, v.y + 1, v.width + 1, v.height - 1);
		data.destroyCollider.x = v.x + 0.5 * (2/v.width) * v.direction;
		data.destroyCollider.y = v.y + 8;
		local list = colliders.getColliding{
			a = data.destroyCollider,
			btype = colliders.BLOCK,
			filter = function(other)
				if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
					return false
				end
				return true
			end
			}
			for _,b in ipairs(list) do
				b:hit(true)
			end
			SFX.play(37)
			data.timer = 0
			data.state = STATE_RETURN
		end
	else
		--When in the same y-coordinates as where it spawned then return to its flying state
		data.timer = data.timer + 1
		v.animationFrame = math.floor(data.timer / 8) % 2
		v.speedY = -2
		if v.y <= v.spawnY then
			data.timer = 0
			data.state = STATE_FLY
		end
	end
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = flaptorSettings.frames
	});
end

--Gotta return the library table!
return flaptor