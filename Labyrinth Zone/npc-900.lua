local npcManager = require("npcManager")
local whistle = require("npcs/ai/whistle")
local monty = require("npcs/ai/montymolehole")

local montyMoles = {}

local onlinePlayNPC = require("scripts/onlinePlay_npc")

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

-- monty moooole
local npcID = NPC_ID;

local ST_CHILL = 0
local ST_HIDDEN = 1
local ST_TELE = 2
local ST_JUMP = 3

local moleData = {}

moleData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 56,
	gfxoffsety = 0,
	gfxheight = 92, 
	width = 42, 
	height = 72, 
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	luahandlesspeed=true,

	keephole = true,
	jumpheight = 5.5,
	holeid = 223,
	--blocknpc = -1
	--lua only
	--death stuff
})

monty.register(npcID)

npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_TAIL, HARM_TYPE_HELD, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]={id=10, speedX=0, speedY=0},
[HARM_TYPE_FROMBELOW]=10,
[HARM_TYPE_NPC]=10,
[HARM_TYPE_TAIL]=10,
[HARM_TYPE_HELD]=10,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

function montyMoles.onInitAPI()
	npcManager.registerEvent(npcID, montyMoles, "onTickNPC")
	npcManager.registerEvent(npcID, montyMoles, "onStartNPC")
	npcManager.registerEvent(npcID, montyMoles, "onTickEndNPC")
	registerEvent(montyMoles, "onDraw")
end

local function getDistance(k,p)
	return k.x - p.x, k.x < p.x
end

local firstTick = true

local function isValidBlock(b)
	return (not b.isHidden) and (not Block.NONSOLID_MAP[b.id] and (not b:mem(0x5A, FIELD_BOOL)))
end

local function overlapsWithBlock(v)
	for k,b in ipairs(Block.getIntersecting(v.x, v.y + v.height, v.x + v.width, v.y + v.height)) do
		if isValidBlock(b) and Block.SOLID_MAP[b.id] then
			return true
		end
	end
	return false
end

local function checkAwake(v, dist, data, needsWhistle)
	if firstTick then return false end
	if ((not needsWhistle) and math.abs(dist) < 300) or whistle.getActive() then
		data.state = ST_TELE
		for k,b in ipairs(Block.getIntersecting(v.x + 2, v.y + 2, v.x + v.width - 2, v.y + v.height - 2)) do
			if isValidBlock(b) and Block.SOLID_MAP[b.id] then
				return false
			end
		end
		for k,b in ipairs(Block.getIntersecting(v.x + 2, v.y + v.height + 2, v.x + v.width - 2, v.y + v.height + 4)) do
			if isValidBlock(b) and b.y >= v.y+v.height-4 then
				return true
			end
		end
		return false
	end
end

--******************************************
--                                         *
--              MONTY MOLES                *
--                                         *
--******************************************

function montyMoles.onStartNPC(v)
	local data = v.data._basegame
	local settings = v.data._settings
	data.wasBuried = ST_HIDDEN
	if v.data._settings.startHidden == false then
		data.wasBuried = ST_CHILL
	else
		data.vanillaFriendly = v.friendly
		v.friendly = true
		v.noblockcollision = true
	end
	data.timer = 0
	data.direction = v.direction
	data.state = data.wasBuried
end

function montyMoles.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	local settings = v.data._settings
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		data.state = data.wasBuried or ST_JUMP
		data.timer = 0
		if data.hasDirt and not moleData.config.keephole then
			monty.removeDirt(v)
		end
		return
	end
	if data.state == nil then
		data.state = data.wasBuried or ST_JUMP
		data.timer = 0
		data.onGround = false
		data.direction = -1
		if data.vanillaFriendly == nil then
			data.vanillaFriendly = v.friendly
		end
	end
	
	if data.state == ST_HIDDEN then --buried
		v.friendly = true
		
		if player2 then
		local p1, dir1 = getDistance(v, player)
		local p2, dir2 = getDistance(v, player2)
		if p1 > p2 then
				data.onGround = checkAwake(v, p2, data, v.data._settings.needsWhistle)
			else
				data.onGround = checkAwake(v, p1, data, v.data._settings.needsWhistle)
			end
		else
			local p1, dir1 = getDistance(v, player)
			data.onGround = checkAwake(v, p1, data, v.data._settings.needsWhistle)
		end
		if data.state == ST_TELE then
			v.noblockcollision = true
			v.speedY = 0
		end
	elseif data.state == ST_TELE then --telegraph
		v.friendly = true
		data.timer = data.timer + 1
		
		if data.timer > 65 then
			data.timer = 0
			SFX.play(4)
			Animation.spawn(1, v.x + 0.5 * v.width, v.y + 0.5 * v.height)
			data.state = ST_JUMP
			if not data.onGround then
				--v.animationFrame = v.animationFrame + 2
				if (not (settings.spawnHole == false)) and not data.hasDirt then
					monty.spawnDirt(v)
				end
			end
			monty.removeObjects(v)
			v.speedY = -NPC.config[npcID].jumpheight
		end
	elseif data.state == ST_JUMP then --jump
		v.friendly = data.vanillaFriendly
		data.timer = data.timer + 1

		if (v.noblockcollision and ((not overlapsWithBlock(v)) or v.speedY > 0)) then
			v.noblockcollision = false
		end
		
		if data.timer > 18 and v.collidesBlockBottom then
			data.timer = 0
			data.state = ST_CHILL
			if v.x > Player.getNearest(v.x, v.y).x then
				v.direction = -1
			else
				v.direction = 1
			end
		end
	elseif data.state == ST_CHILL then
		v.speedX = 1.81 * v.direction
		if v.collidesBlockBottom then
			data.timer = data.timer - 1
			if data.timer % 96 == 0 then
				v.speedY = -4
			end
		else
			v.animationFrame = 1
		end
	end
end

function montyMoles.onTickEndNPC(v)	
	local data = v.data._basegame
	local frames = NPC.config[npcID].frames
	local framestyleMod = NPC.config[npcID].framestyle + 1
	if framestyleMod == 3 then framestyleMod = 4 end
	local framesFull = frames * framestyleMod
	
	if data.timer == nil then
		data.timer = 0
		data.direction = v.direction
	end
	
	if data.state == ST_JUMP then --jump
		v.animationFrame = framesFull
	elseif data.state == ST_HIDDEN then --buried
		v.animationFrame = 999
		v.speedY = -0.26
	elseif data.state == ST_TELE then --telegraph
		v.animationFrame = math.floor(data.timer / NPC.config[npcID].framespeed)%2 + framesFull + 1
		if not v.collidesBlockBottom then
			v.speedY = -0.26
			if not data.onGround then
				v.animationFrame = v.animationFrame + 2
			end
		end
	else --run
		if v.direction == DIR_LEFT then
			v.animationFrame = math.floor(data.timer / NPC.config[npcID].framespeed) % frames
		else
			v.animationFrame = math.floor(data.timer / NPC.config[npcID].framespeed) % frames + 2
		end
		if framestyleMod == 2 or framestyleMod == 4 then
			v.animationFrame = v.animationFrame + frames * 0.5 + frames * 0.5 * data.direction
		end
		if framestyleMod == 4 then
			if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x132, FIELD_WORD) > 0 or v:mem(0x134, FIELD_WORD) > 0 then
				v.animationFrame = v.animationFrame + 2 * frames
			end
		end
	end
	
	firstTick = false
end

onlinePlayNPC.onlineHandlingConfig[788] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			timer = data.timer,
			direction = data.direction,
			onGround = data.onGround,
			state = data.state,
			vanillaFriendly = data.vanillaFriendly,
			wasBuried = data.wasBuried,
			hasDirt = data.hasDirt,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.timer = receivedData.timer
		data.direction = receivedData.direction
		data.onGround = receivedData.onGround
		data.state = receivedData.state
		data.vanillaFriendly = receivedData.vanillaFriendly
		data.wasBuried = receivedData.wasBuried
		data.hasDirt = receivedData.hasDirt
	end,
}

return montyMoles