--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local redirector = require("redirector")
local effectconfig = require("game/effectconfig")


--Create the library table
local bud = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local budSettings = {
	id = npcID,
	gfxheight = 38,
	gfxwidth = 38,
	width = 38,
	height = 38,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 20,
	framestyle = 1,
	framespeed = 8, 
	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=false,
	grabtop=false,
	
}local config = npcManager.setNpcSettings(budSettings)

--Applies NPC settings
npcManager.setNpcSettings(budSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
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
		--[HARM_TYPE_JUMP]=761,
		--[HARM_TYPE_FROMBELOW]=npcID,
		--[HARM_TYPE_NPC]=npcID,
		--[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function bud.onInitAPI()
	npcManager.registerEvent(npcID, bud, "onTickEndNPC")
	registerEvent(bud, "onNPCKill")
end

function effectconfig.onTick.TICK_BIDDYBUD(v)
    v.animationFrame = math.min(v.frames-1,math.floor((v.lifetime-v.timer)/v.framespeed))
end

function bud.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end

	local data = v.data
	local settings = v.data._settings
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true

		--speed
		if settings.buddyspeed == nil then settings.buddyspeed = 1.2 end
		v.speedX = settings.buddyspeed * v.direction
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		v.speedX = 1.2 * v.direction
	end
	
	for _,bgo in ipairs(BGO.getIntersecting(v.x+(v.width/2)-0.5,v.y+(v.height/2),v.x+(v.width/2)+0.5,v.y+(v.height/2)+0.5)) do
		if redirector.VECTORS[bgo.id] and redirector.VECTORS[bgo.id].y == 0 then -- If this is a redirector and has a speed associated with it
			local redirectorSpeed = redirector.VECTORS[bgo.id] * settings.buddyspeed -- Get the redirector's speed and make it match the speed in the NPC's settings		
			-- Now, just put that speed from earlier onto the NPC
			v.speedX = redirectorSpeed.x
			v.speedY = redirectorSpeed.y
		elseif bgo.id == redirector.TERMINUS then -- If this BGO is one of the crosses
			-- Simply make the NPC stop moving
			v.speedX = 0
			v.speedY = 0
		end
	end
	
	if settings.color == 1 then --green
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 4
	elseif settings.color == 2 then --yellow
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 8
	elseif settings.color == 3 then --blue
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 12
	elseif settings.color == 4 then --pink
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 16
	else --red
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = budSettings.frames
	});
end

function bud.onNPCKill(eventObj, killedNPC, killReason)
	if killedNPC.id ~= npcID then return end

	local v = killedNPC
	local data = v.data
	local settings = data._settings

	if settings.color == nil then
		settings.color = 0
	end

	--create the death effect
	if killReason == 1 then --if its a stomp
		Animation.spawn(751, v.x, v.y, settings.color+1)
	elseif killReason == 2 or killReason == 3 or killReason == 4 or killReason == 7 then --if killed by these reasons
		Animation.spawn(752, v.x, v.y, settings.color+1)
	end
end

return bud