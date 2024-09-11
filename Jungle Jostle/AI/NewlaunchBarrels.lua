local launchBarrel = {}

local npcManager = require("npcManager")
local lineguide = require("lineguide")
local utils = require("npcs/npcutils")

local klonoa = require("characters/klonoa")
local broadsword = require("characters/unclebroadsword")
local samus = require("characters/samus")

local onlinePlayNPC = require("scripts/onlinePlay_npc")

launchBarrel.sfx_enter = Misc.resolveSoundFile("launchbarrel_entering")
launchBarrel.sfx_fire = Misc.resolveSoundFile("launchbarrel_fire")
launchBarrel.sfx_break = Misc.resolveSoundFile("Barrel_break")

local playerData = {}

local BarrelNumber = Graphics.loadImage(Misc.resolveFile("numbers.png"))

local STATE_EMPTY = 0
local STATE_FULL = 1

local cos = math.cos
local sin = math.sin

local radtodeg = math.deg
local degtorad = math.rad

local types = {
	"rotate",
	"auto",
	"straight",
}

for _,v in ipairs(types) do
	launchBarrel[v] = {}
end

local settings = {
	gfxwidth = 0,
	gfxheight = 0,
	width = 64,
	height = 64,
	frames = 2,
	framespeed = 32,
	framestyle = 0,
	score = 0,
	nogravity = true,
	noiceball = true,
	noyoshi = true,
	nofireball = true,
	jumphurt = true,
	nohurt = true,
	ignorethrownnpcs = true,
	noblockcollision = true,
	foreground=true,
	notcointransformable = true,
	staticdirection = true,

	--rotationInterval = 45,
	--rotationSpeed = 2,
	--force = 15,
	delay = 8,
	cooldown = 30,
	correctgravity = true, -- Apply vertical momentum.
	launchtimer = 65, -- If -1, player is launched until hitting a wall.
	second = 60,
}

local idslist = {}

function launchBarrel.registerBarrel(id, typ, cfg)
	launchBarrel[id] = {}
	settings.id = id
	if cfg then
		cfg = table.join(cfg, settings)
	else
		cfg = settings
	end
	table.insert(idslist, id)
	launchBarrel[id].config = npcManager.setNpcSettings(cfg)
	npcManager.registerHarmTypes(id, {}, {})
	
	npcManager.registerEvent(id, launchBarrel[typ], "onTickNPC")
	npcManager.registerEvent(id, launchBarrel, "onDrawNPC")
	npcManager.registerEvent(id, launchBarrel, "onInputUpdateNPC")
	
	lineguide.registerNpcs(id)
	
end

registerEvent(launchBarrel, "onTick")

local function getGFXSize(npc)
	return utils.gfxwidth(npc), utils.gfxheight(npc)
end

local function centerPlayer(p, npc)
	p.x = npc.x + npc.width*0.5 - p.width*0.5
	p.y = npc.y + npc.height*0.5 - p.height*0.5
end

local function updateSizeCache(npc, data)
	data.gfxwidth = npc:mem(0xC0, FIELD_DFLOAT)
	data.gfxheight = npc:mem(0xB8, FIELD_DFLOAT)
	data.width = npc.width
	data.height = npc.height
			
	if data.flipDirection == nil then
		data.flipDirection = 1
		data.flipTimer = 0
	end
	
	local img = Graphics.sprites.npc[npc.id].img
	
	data.imgwidth = img.width
	data.imgheight = img.height
end

local function drawBarrel(npc, data, sprite)
	local config = launchBarrel[npc.id].config

	sprite.x = npc.x + npc.width*0.5 + config.gfxoffsetx
	sprite.y = npc.y + npc.height*0.5 + config.gfxoffsety
	local p = -45
	if config.foreground then
		p = -15
	end
	
	if data.memory > 0 then
		if data.state == STATE_FULL then
			data.animationState = 1
		else
			data.animationState = npc.animationFrame
		end
	else
		data.animationState = 0
	end
	
	local y = sprite.texposition.y
	sprite.texposition.y = y - utils.gfxheight(npc)*data.animationState
	
	if data.opacity == nil then
		data.opacity = 1
	end
	
	sprite:draw{color = Color.white .. data.opacity, priority = p, sceneCoords = true}
	sprite.texposition.y = y
	sprite.frame = 1
	utils.hideNPC(npc)
end


local playersRunKeys = {}
local function makePlayerInvisible(p)
	--p.forcedState = 8

	p.speedX = 0
	p.speedY = 0

	--make player invisible
	p:mem(0x140, FIELD_WORD, 2);
	p:mem(0x142, FIELD_BOOL, true);
	-- p.forcedTimer = 0	-- Maybe not needed?
end

local function dataCheck(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	
	local img = Graphics.sprites.npc[npc.id].img
	
	if data.sprite == nil then
		npc.speedX = 0
		npc.speedY = 0
		
		data.state = STATE_EMPTY
		data.cooldown = 0
		data.waitdown = -1
		
		if npc:mem(0x138, FIELD_WORD) ~= 0 then
			local config = NPC.config[npc.id]
			npc.width = config.width
			npc.height = config.height
		end

		local w, h = getGFXSize(npc)
		
		
		data.rotation = (settings.startAngle) % 360
		data.angOffset = data.rotation
		
		data.sprite = Sprite.box{x = npc.x, y = npc.y, width = w, height = h, texture = img, rotation = data.rotation, align = Sprite.align.CENTRE}
		data.sprite.texscale = vector(img.width, img.height)
	else
		if data.gfxwidth ~= npc:mem(0xC0, FIELD_DFLOAT) or data.gfxheight ~= npc:mem(0xB8, FIELD_DFLOAT) or (data.gfxwidth == 0 and data.width ~= npc.width) or (data.gfxheight == 0 and data.height ~= npc.height) then
			data.sprite.width,data.sprite.height = getGFXSize(npc)
		end
		
		if data.imgwidth ~= img.width or data.imgheight ~= img.height then
			data.sprite.texscale = vector(img.width, img.height)
		end
	end

	updateSizeCache(npc,data)
end

local momentumEvents = {}
local trailEvents = {}
local playersInBarrel = {}

local defaultRunSpeed = 0

local function enterBarrel(npc, p)
	local data = npc.data._basegame

	local a = Animation.spawn(248, (p.x + p.width*0.5 + npc.x + npc.width*0.5)*0.5, (p.y + p.height*0.5 + npc.y + npc.height*0.5)*0.5)
	a.x = a.x - a.width*0.5
	a.y = a.y - a.height*0.5

	--Resets momentum from another cannon if the momentum event is still running
	if momentumEvents[p.idx] and momentumEvents[p.idx].waiting then
		momentumEvents[p.idx]:abort()
		Defines.player_runspeed = defaultRunSpeed
		momentumEvents[p.idx] = nil
	end
	
	if trailEvents[p.idx] and trailEvents[p.idx].waiting then
		trailEvents[p.idx]:abort()
		trailEvents[p.idx] = nil
	end

	if player.character == CHARACTER_SAMUS then
		samus.setMorph(false)
	elseif player.character == CHARACTER_KLONOA then
		klonoa.disableRing()
	end

	centerPlayer(p, npc)
	playersRunKeys[p.idx] = p.keys.run
	makePlayerInvisible(p)
	playerData[p.idx] = npc
	data.player = p
	data.state = STATE_FULL
	data.waitdown = launchBarrel[npc.id].config.delay

	SFX.play(launchBarrel.sfx_enter)
end

--Used to determine when to stop applying momentum after firing out of a cannon
local validstates = {[0]=true, [1]=true, [2]=true, [4]=true, [5]=true, [11]=true, [12]=true, [41]=true,[500]=true}

local function exitBarrel(npc, p, round)
	local data = npc.data._basegame
	local settings = npc.data._settings
	local config = launchBarrel[npc.id].config
	local ang
	if round == false then
		ang = degtorad(data.sprite.rotation - 90)
	else
		ang = degtorad(math.floor((data.sprite.rotation - data.angOffset)/settings.interval + 0.5)*settings.interval + data.angOffset - 90)
	end
	local ang_cos = cos(ang)
	local ang_sin = sin(ang)
	local hwidth = npc.width*0.5
	local hheight = npc.height*0.5

	Routine.setFrameTimer(5, function()
		playerData[p.idx] = nil
	end)
	playersRunKeys[p.idx] = nil
	trailEvents[p.idx] = Routine.run(function()
		for i = 1, 8 do
			Routine.waitFrames(5)
			local a = Animation.spawn(250, p.x + p.width*0.5, p.y + p.height*0.5)
			a.x = a.x - a.width*0.5
			a.y = a.y - a.height*0.5
		end
	end)

	if player.character == CHARACTER_KLONOA then
		klonoa.resetFlutter()
		klonoa.enableRing()
	elseif player.character == CHARACTER_PEACH then
		p:mem(0x18, FIELD_BOOL, false)
	end

	centerPlayer(p, npc)
	
		p.forcedState = 0
		local s = settings.power*ang_cos
		-- p.speedX = s
		p.speedX = 0
		p.speedY = settings.power*ang_sin
		defaultRunSpeed = Defines.player_runspeed
		
		p.keys.jump = false
		momentumEvents[p.idx] = Routine.run(function()
			applyMomentum = true
			vert = config.correctgravity
			ticks = config.launchtimer
			
			Defines.player_runspeed = math.abs(s)
			p.speedX = s
		
		while applyMomentum and Defines.player_runspeed > defaultRunSpeed do
			-- Stop momentum once we hit the ground, enter certain forced states, hit a wall, or enter a liquid.
			if p:isOnGround() or not validstates[p.forcedState]
			or (p:mem(0x148, FIELD_WORD) ~= 0 or p:mem(0x14C, FIELD_WORD) ~= 0 or p:mem(0x14A, FIELD_WORD) ~= 0)
			or p:mem(0x34, FIELD_WORD) == 2 or (player.character == CHARACTER_KLONOA and klonoa.isFlapping()) then
				applyMomentum = false
			end
			
			if ticks ~= -1 then
				if ticks == 0 then
					applyMomentum = false
				else
					ticks = ticks - 1
				end
			end
				
			if applyMomentum then
				Defines.player_runspeed = math.min(Defines.player_runspeed, math.abs(p.speedX))
				p.speedX = p.speedX*0.97
				if vert and ang_sin >= -0.001 then
					p.speedY = p.speedY - Defines.player_grav + 0.0001
				end

				Routine.skip()
			end
		end
		Defines.player_runspeed = defaultRunSpeed
	end)
	data.state = STATE_EMPTY
	data.cooldown = config.cooldown
	data.waitdown = -1

	local a = Animation.spawn(249, npc.x + hwidth, npc.y + hheight)
	a.x = a.x - a.width*0.5 + ang_cos*hwidth
	a.y = a.y - a.height*0.5 + ang_sin*hheight

	SFX.play(launchBarrel.sfx_fire)
	
	if settings.skullbarrel then
		SFX.play(launchBarrel.sfx_break)
	--Literally just took this part from 8luestorm's barrels lol
		for i = -1,1 do
			if i ~= 0 then
				local debris1 = Animation.spawn(761,npc.x,npc.y)
				debris1.speedX = 2*i
				debris1.speedY = -4 - i
				local debris2 = Animation.spawn(762,npc.x,npc.y)
				debris2.speedX = 2*i
				debris2.speedY = -4 + i
				debris2.animationFrame = 2
				local debris3 = Animation.spawn(761,npc.x,npc.y)
				debris3.speedX = 3*i
				debris3.speedY = -5 - i
				debris3.animationFrame = 3
			end
		end
		npc:kill(HARM_TYPE_OFFSCREEN)
	end
end

local function checkPlayerAnimation(n)
	 if n < 2 or (n > 3 and n < 6) or (n > 10 and n < 13) or n == 41 then
		 return true
	 end
end

local function checkPlayersForBarrel(npc)
	if npc.friendly then return end
	local npcCX = npc.x + npc.width*0.5
	local npcCY = npc.y + npc.height*0.5
	for _, p in ipairs(Player.get()) do
		if NPC.config[npc.id].playerCharacter == nil or (NPC.config[npc.id].playerCharacter == p.character) then
			if (playerData[p.idx] == nil or not playerData[p.idx].isValid or playerData[p.idx].isHidden) and checkPlayerAnimation(p.forcedState) and p.deathTimer == 0 and math.abs(p.x + p.width*0.5 - npcCX) < npc.width*0.5 and math.abs(p.y + p.height*0.5 - npcCY) < npc.height*0.5 and npc:mem(0x12A, FIELD_WORD) > 0 and
			--[[broadsword is not attacking --]](player.character ~= CHARACTER_UNCLEBROADSWORD or broadsword.getAttackState() <= 0) then
				enterBarrel(npc, p)
				break
			end
		end
	end
end

local function hideHeldItem(p)
	if p.holdingNPC then
		p.holdingNPC.x = p.x - 65536
		p.holdingNPC.y = p.y - 65536
	end
end

function launchBarrel.onTick()
	for _, p in ipairs(Player.get()) do
		if playerData[p.idx] then
			if not playerData[p.idx].isValid then
				playerData[p.idx] = nil
			elseif playerData[p.idx].isHidden then
				local d = playerData[p.idx].data._basegame
				d.state = STATE_EMPTY
				playerData[p.idx] = nil
			end
		end
	end
end
	
function launchBarrel.onInputUpdateNPC(npc)
	if not npc.isGenerator and npc.data._basegame then
		local data = npc.data._basegame
		local p = data.player
		data.memory = data.memory or 0
		if data.state == STATE_FULL and p then
			p.keys.run = playersRunKeys[p.idx]
			p.keys.altJump = false
			p.keys.altRun = false
			if player.character == CHARACTER_KLONOA then
				klonoa.forceJumped()
			end
				npc.ai3 = npc.ai3 + 1;
					if npc.ai3 >= NPC.config[npc.id].second then
						if data.memory > 0 then
							data.memory = data.memory - 1;
						end
						npc.ai3 = 2;
					end
		elseif data.state == STATE_EMPTY then
			npc.ai3 = 0;
		end
	end
end

function launchBarrel.onDrawNPC(npc)
	if npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	local data = npc.data._basegame
	local settings = npc.data._settings

	dataCheck(npc)	
	drawBarrel(npc, data, data.sprite)
	
	if data.numberSprite == nil then
		data.numberSprite = Sprite{x=0,y=0,image=BarrelNumber,frames=9}
	end

	if data.state == STATE_FULL then
		hideHeldItem(data.player)
		data.numberSprite.x = npc.x+npc.width/2 - 30
		data.numberSprite.y = npc.y+npc.height/2 - 32
		if settings.counttimer > 0 then
			data.numberSprite:draw{sceneCoords = true, priority = p, frame = 1 * data.memory}
		end
	else
		if settings.counttimer > 0 and data.animationState > 0 then
			data.numberSprite.x = npc.x+npc.width/2 - 30
			data.numberSprite.y = npc.y+npc.height/2 - 32
			data.numberSprite:draw{sceneCoords = true, priority = p, frame = 1 * data.memory}
		end
	end
end

local function updateRotation(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	local sprite = data.sprite
	
	sprite.rotation = math.floor((data.rotation - data.angOffset)/settings.interval)*settings.interval + data.angOffset
	
	local curRotInterval = (data.rotation - data.angOffset) % settings.interval
	
	local nonRotInterval
	
	if settings.interval > settings.rotSpeed*8 then
		nonRotInterval = settings.interval-settings.rotSpeed*8
	else
		nonRotInterval = 0
	end
	
	if curRotInterval >= nonRotInterval then
		sprite.rotation = sprite.rotation + settings.interval*(curRotInterval - nonRotInterval)/(settings.interval - nonRotInterval)
		if settings.flipTime ~= 0 then
			if data.flipDirection == 1 then
				if data.flipTimer >= npc.data._settings.flipTime then
					data.flipDirection = -1
					data.flipTimer = 0
				end
			else
				if npc.direction == DIR_LEFT then
					if data.rotation >= settings.startAngle then
						data.flipDirection = 1
						data.flipTimer = 0
					end
				else
					if data.rotation <= settings.startAngle then
						data.flipDirection = 1
						data.flipTimer = 0
					end
				end
			end
		end
	end
end

local function clearRotation(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	if (data.rotation-data.angOffset)%settings.interval > math.max(0,settings.interval-settings.rotSpeed*8) then
		data.rotation = data.rotation + settings.rotSpeed*npc.direction
		updateRotation(npc)
	end
end

function launchBarrel.rotate.onTickNPC(npc)
	utils.applyLayerMovement(npc)
	if Defines.levelFreeze or npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	if npc:mem(0x136, FIELD_BOOL) then
		npc.speedX = 0
		npc.speedY = 0
		return
	end
	
	dataCheck(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	
	data.rotation = data.rotation + settings.rotSpeed*npc.direction*data.flipDirection
	updateRotation(npc)

	data.flipTimer = data.flipTimer + 1

	if data.cooldown > 0 then
		data.cooldown = data.cooldown - 1
	elseif data.state == STATE_FULL then
		local p = data.player
		centerPlayer(p, npc)
		makePlayerInvisible(p)
		p:mem(0x60, FIELD_BOOL, true)
		p:mem(0x11E, FIELD_WORD, 1)
		if data.waitdown > 0 then
			data.waitdown = data.waitdown - 1
		elseif p.keys.jump == KEYS_PRESSED or data.memory <= 0 and settings.counttimer > 0 then
			exitBarrel(npc, p)
		end
	else
		checkPlayersForBarrel(npc)
		if data.memory >= 0 then
			data.memory = settings.counttimer
		end
	end
end

function launchBarrel.auto.onTickNPC(npc)
	utils.applyLayerMovement(npc)
	if Defines.levelFreeze or npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	if npc:mem(0x136, FIELD_BOOL) then
		npc.speedX = 0
		npc.speedY = 0
		return
	end
	
	dataCheck(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	
	if data.state == STATE_FULL then
		clearRotation(npc)
	end

	if data.cooldown > 0 then
		data.cooldown = data.cooldown - 1
	elseif data.state == STATE_FULL then
		local p = data.player
		centerPlayer(p, npc)
		makePlayerInvisible(p)
		p:mem(0x60, FIELD_BOOL, true)
		p:mem(0x11E, FIELD_WORD, 1)
		if data.waitdown > 0 then
			data.waitdown = data.waitdown - 1
		elseif data.waitdown <= 0 then
			exitBarrel(npc, data.player)
		end
	else
		data.flipTimer = data.flipTimer + 1
		data.rotation = data.rotation + settings.rotSpeed*npc.direction*data.flipDirection
		checkPlayersForBarrel(npc)
		updateRotation(npc)
	end
end

function launchBarrel.straight.onTickNPC(npc)
	utils.applyLayerMovement(npc)
	if Defines.levelFreeze or npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	if npc:mem(0x136, FIELD_BOOL) then
		npc.speedX = 0
		npc.speedY = 0
		return
	end
	
	dataCheck(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings

	if data.cooldown > 0 then
		data.cooldown = data.cooldown - 1
	elseif data.state == STATE_FULL then
		local p = data.player
		centerPlayer(p, npc)
		makePlayerInvisible(p)
		p:mem(0x60, FIELD_BOOL, true)
		p:mem(0x11E, FIELD_WORD, 1)
		if data.waitdown > 0 then
			data.waitdown = data.waitdown - 1
		elseif p.keys.jump == KEYS_PRESSED or data.memory <= 0 and settings.counttimer > 0 then
			exitBarrel(npc, p, false)
		end
	else
		checkPlayersForBarrel(npc)
		if data.memory >= 0 then
			data.memory = settings.counttimer
		end
	end
end

local npcList = {961, 962, 963}

onlinePlayNPC.onlineHandlingConfig[#npcList] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			gfxwidth = data.gfxwidth,
			gfxheight = data.gfxheight,
			width = data.width,
			height = data.height,
			flipDirection = data.flipDirection,
			flipTimer = data.flipTimer,
			imgwidth = data.imgwidth,
			imgheight = data.imgheight,
			state = data.state,
			memory = data.memory,
			animationState = data.animationState,
			opacity = data.opacity,
			sprite = data.sprite,
			waitdown = data.waitdown,
			cooldown = data.cooldown,
			rotation = data.rotation,
			player = data.player,
			angOffset = data.angOffset,
			numberSprite = data.numberSprite,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.gfxwidth = receivedData.gfxwidth
		data.gfxheight = receivedData.gfxheight
		data.width = receivedData.width
		data.height = receivedData.height
		data.flipDirection = receivedData.flipDirection
		data.flipTimer = receivedData.flipTimer
		data.imgwidth = receivedData.imgwidth
		data.imgheight = receivedData.imgheight
		data.state = receivedData.state
		data.memory = receivedData.memory
		data.animationState = receivedData.animationState
		data.opacity = receivedData.opacity
		data.sprite = receivedData.sprite
		data.waitdown = receivedData.waitdown
		data.cooldown = receivedData.cooldown
		data.rotation = receivedData.rotation
		data.player = receivedData.player
		data.angOffset = receivedData.angOffset
		data.numberSprite = receivedData.numberSprite
	end,
}

return launchBarrel
