local blockManager = require("blockManager")

local onlinePlay = require("scripts/onlinePlay")
local onlinePlayPlayers = require("scripts/onlinePlay_players")


local boostBlock = {}
local blockID = BLOCK_ID

local boostBlockSettings = {
	id = blockID,
	
	frames = 16,
	framespeed = 6,

	lightradius = 96,
	lightbrightness = 0.75,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.orange,
}

blockManager.setBlockSettings(boostBlockSettings)

function boostBlock.onInitAPI()
	blockManager.registerEvent(blockID, boostBlock, "onCollideBlock")
	registerEvent(boostBlock,"onTick")
	registerEvent(boostBlock,"onDraw")
end



local dashStartCommand = onlinePlay.createCommand("dashBlock_dashStart",onlinePlay.IMPORTANCE_MAJOR)
local dashSound = Misc.resolveSoundFile("boostBlock.wav")

local pSpeedValues = {
	[CHARACTER_MARIO] = 35,
	[CHARACTER_LUIGI] = 40,
	[CHARACTER_PEACH] = 80,
	[CHARACTER_TOAD] = 60,
	[CHARACTER_LINK] = 10,
}


local function canBoost(p)
	if p.forcedState ~= FORCEDSTATE_NONE or p:mem(0x0C,FIELD_BOOL) or p.climbing then
		return false
	end

	return true
end

local function startBoost(p)
	local data = p.data.boostBlock

	if data == nil then
		data = {
			trailEmitter = Particles.Emitter(0,0,Misc.resolveFile("boost_trail.ini")),
		}
		p.data.boostBlock = data
	end

	data.boostDirection = p.direction
	data.boostTimer = 64

	data.effectsTimer = 35

	data.hasLeftoverSpeed = true

	if p.speedX*data.boostDirection < 8 then
		p.speedX = 8*data.boostDirection
	end

	if onlinePlayPlayers.canMakeSound(p) then
		SFX.play(dashSound)
	end
end


function boostBlock.onCollideBlock(v,p)
	if type(p) ~= "Player" or not onlinePlayPlayers.ownsPlayer(p) then
		return
	end

	if (p.x + p.width) < v.x or p.x > (v.x + v.width) or (p.y + p.height) > (v.y + 4) then
		return
	end

	if (p.data.boostBlock ~= nil and p.data.boostBlock.boostTimer > 0) or not canBoost(p) then
		return
	end

	if p:mem(0x50,FIELD_BOOL) then
		if p.keys.left then
			p.direction = DIR_LEFT
		elseif p.keys.right then
			p.direction = DIR_RIGHT
		end

		p:mem(0x50,FIELD_BOOL,false)
	end

	if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
		dashStartCommand:send(0, p.direction)
	end

	startBoost(p)
end

function dashStartCommand.onReceive(sourcePlayerIdx, direction)
	local p = Player(sourcePlayerIdx)

	p.direction = direction
	startBoost(p)
end


local function runSpeedLimitHack(p)
	-- Disabling the run key allows the player to go above the running speed cap
	if p.keys.run then
		p:mem(0x62,FIELD_WORD,1) -- allows the player to still hold things
	end

	p.keys.run = false
end

local function updatePlayer(p)
	local data = p.data.boostBlock
	if data == nil then
		return
	end

	if not canBoost(p) then
		data.trailEmitter.enabled = false
		data.hasLeftoverSpeed = false
		data.boostTimer = 0
		data.effectsTimer = 0

		return
	end

	data.trailEmitter.enabled = (data.effectsTimer > 0)
	data.effectsTimer = math.max(0,data.effectsTimer - 1)

	if data.boostTimer <= 0 then
		if data.hasLeftoverSpeed then
			if math.abs(p.speedX) < Defines.player_runspeed then
				data.hasLeftoverSpeed = false
				return
			end

			if data.boostDirection == DIR_RIGHT and not p.keys.right then
				p.speedX = p.speedX - 0.25
			elseif data.boostDirection == DIR_LEFT and not p.keys.left then
				p.speedX = p.speedX + 0.25
			end

			runSpeedLimitHack(p)
		end

		return
	end

	if (data.boostDirection == DIR_RIGHT and p.keys.right) or (data.boostDirection == DIR_LEFT and p.keys.left) then
		if p.powerup == POWERUP_LEAF or p.powerup == POWERUP_TANOOKI then
			p:mem(0x168,FIELD_FLOAT,pSpeedValues[p.character] or 0)
		end

		p.speedX = math.clamp(p.speedX + 2*data.boostDirection,-14,14)
		data.boostTimer = math.max(0,data.boostTimer - 1)
	else
		p.speedX = math.clamp(p.speedX + 1*data.boostDirection,-14,14)
		data.boostTimer = math.max(0,data.boostTimer - 2)
	end

	runSpeedLimitHack(p)
end


function boostBlock.onTick()
	for _,p in ipairs(Player.get()) do
		updatePlayer(p)
	end
end

function boostBlock.onDraw()
	for _,p in ipairs(Player.get()) do
		local data = p.data.boostBlock

		if data ~= nil and (data.trailEmitter.enabled or data.trailEmitter:count() > 0) then
			data.trailEmitter:setParam("startFrame",(data.boostDirection == DIR_RIGHT and 1) or 0)
			data.trailEmitter.x = p.x + p.width*0.5 - p.direction*8
			data.trailEmitter.y = p.y + p.height*0.5
			data.trailEmitter:draw(-26,true)
		end
	end
end



return boostBlock