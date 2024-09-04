local npcManager = require("npcManager")

local card = {}
local npcID = NPC_ID

local cardSettings = {
	id = npcID,
	gfxwidth = 44,
	gfxheight = 64,
	width = 40,
	height = 64,
	frames = 10,
	framestyle = 0,
	framespeed = 4,
	noblockcollision = 0,
	speed = 1,
	playerblock=false,
	playerblocktop=false,
	npcblock=false,
	npcblocktop=false,
	luahandlesspeed=true,
	jumphurt=true,
	nowaterphysics=true,
	noblockcollision=true,
	nohurt=true,
	spinjumpsafe=false,
	nogravity=true,
	nofireball=true,
	noiceball=true,
	noyoshi=true,
	
	maxheight=32, --The maximum amount of upwards movement the Card will do when triggered. If its speed isn't high enough, it will stop prematurely before reaching this value, however!
	upspeed=2, --The speed that the Card moves upwards when triggered. Will not move beyond the maxheight value relative to the spawning location of the Card.
	revealtime=60 --The amount of time the Card will spend once revealed before releasing its contents.
}

npcManager.registerHarmTypes(npcID,{},{});

local STATE_IDLE = 0
local STATE_TRIGGERED = 1
local STATE_REVEALED = 2
local STATE_RETURN = 3

local collided = { }

local playerProjectiles = {
	[13] = true,
	[265] = true,
	[667] = true,
	[171] = true,
	[292] = true,
	[291] = true,
	[266] = true,
	[436] = true
}

local configFile = npcManager.setNpcSettings(cardSettings)

local function giveReward(v)
	if v.ai1 > 0 then
		local contentsWidth = NPC.config[v.ai1].gfxwidth
		if contentsWidth == 0 then
			contentsWidth = NPC.config[v.ai1].width
		end
		local contentsHeight = NPC.config[v.ai1].gfxheight
		if contentsHeight == 0 then
			contentsHeight = NPC.config[v.ai1].height
		end
		local npcSpawnX = v.x + 0.5 * v.width
		local npcSpawnY = v.y + 0.5 * v.height
		local f = NPC.spawn(v.ai1, npcSpawnX, npcSpawnY, v:mem(0x146, FIELD_WORD), false, true)
		
		f.data._basegame = {}
		f.direction = v.data._basegame.spawnDirection
		f.layerName = "Spawned NPCs"
		
		SFX.play(34)
	end
	if v.data._settings.coins > 0 then
		Misc.coins(v.data._settings.coins, true)
		Effect.spawn(11,v.x + v.width*0.5, v.y + v.height*0.5)
	end
	if v.data._settings.score > 0 then
		Misc.givePoints(v.data._settings.score, vector(v.x+0.5*v.width, v.y+0.5*v.height), false)
	end
end

function card.onInitAPI()
	npcManager.registerEvent(npcID, card, "onTickNPC")
	npcManager.registerEvent(npcID, card, "onDrawNPC")
end

function card.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	local settings = v.data._settings
	
	if data.cardAIState == nil then
		data.cardAIState = STATE_IDLE
		data.cardTimer = 0
		local hitboxMargin = 8 --thanks redigit
		data.cardHitbox = Colliders.Box(v.x-hitboxMargin, v.y-hitboxMargin, v.width+hitboxMargin*2, v.height+hitboxMargin*2)
		data.cardMaxHeight = configFile.maxheight * -1 + v.spawnY
		data.cardUpSpeed = configFile.upspeed * -1
		data.revealFrame = configFile.frames + settings.revealFace - 5
		if data.revealFrame < configFile.frames - 4 then
			data.revealFrame = configFile.frames - 4
		end
		if settings.revealFace == 0 then
			if v.ai1 > 0 then
				data.revealImage = Graphics.loadImageResolved("npc-" .. v.ai1 .. ".png")
			else
				if settings.coins > 0 then
					data.revealFrame = configFile.frames - 1 -- Coin face
				else
					data.revealFrame = configFile.frames - 4 -- Blank face
				end
			end
		else
			data.revealImage = nil
		end
		data.spawnDirection = -1
	end
	
	if data.cardAIState ~= STATE_RETURN then
		v.direction = 1
	else
		v.direction = -1
	end
	
	if (not v.isHidden) and (v:mem(0x124, FIELD_WORD) ~= 0) then
		if data.cardAIState == STATE_IDLE then
			if settings.playerTrigger then
				for _,p in ipairs(Player.get()) do
					if Colliders.collide(p, data.cardHitbox) then
						data.cardAIState = STATE_TRIGGERED
					end
				end
			end
			--Only check once for collided NPCs. Probably slightly more performant.
			if settings.projectileTrigger or settings.npcTrigger then
				collided = Colliders.getColliding{
					a = data.cardHitbox,
					btype = Colliders.NPC
				}
				if settings.projectileTrigger then
					for _,f in ipairs(collided) do
						if f:mem(0x136, FIELD_BOOL) and f.id ~= npcID then
							data.cardAIState = STATE_TRIGGERED
						end
					end
				end
				if settings.npcTrigger then
					for _,f in ipairs(collided) do
						if not f:mem(0x136, FIELD_BOOL) and f.id ~= npcID then
							data.cardAIState = STATE_TRIGGERED
						end
					end
				end
			end
			if settings.timeTrigger >= 0 then
				if data.cardTimer >= settings.timeTrigger then
					data.cardAIState = STATE_TRIGGERED
					data.cardTimer = 0
				else
					data.cardTimer = data.cardTimer + 1
				end
			end
		elseif data.cardAIState == STATE_TRIGGERED then
			v.speedX = 0
			if v.y > data.cardMaxHeight then
				v.speedY = data.cardUpSpeed
			else
				v.y = data.cardMaxHeight
				v.speedY = 0
			end
			if v.animationFrame == data.revealFrame then
				data.cardAIState = STATE_REVEALED
			end
		elseif data.cardAIState == STATE_REVEALED then
			if data.cardTimer >= configFile.revealtime then
				giveReward(v)
				if settings.respawn then
					data.cardAIState = STATE_RETURN
					data.cardTimer = 0
				else
					Effect.spawn(10,v.x + v.width*0.5 - 16, v.y + v.height*0.5 - 16)
					data.cardAIState = nil
					v:kill(9)
				end
			else
				data.cardTimer = data.cardTimer + 1
			end
		elseif data.cardAIState == STATE_RETURN then
			v.speedX = 0
			if v.y < v.spawnY then
				v.speedY = data.cardUpSpeed * -1
			else
				v.y = v.spawnY
				v.speedY = 0
			end
			if v.animationFrame == 0 then
				data.cardAIState = STATE_IDLE
			end
		end
	end
end

function card.onDrawNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	local settings = v.data._settings
	
	-- animation code
	if data.cardAIState == STATE_IDLE then
		v.animationFrame = 0
		v.animationTimer = 0
	elseif data.cardAIState == STATE_TRIGGERED then
		if v.animationFrame >= configFile.frames - 4 then
			v.animationFrame = data.revealFrame
			v.animationTimer = 0
		end
	elseif data.cardAIState == STATE_REVEALED then
		v.animationFrame = data.revealFrame
		v.animationTimer = 0
		if settings.revealFace == 0 and v.ai1 > 0 then
			local contentsWidth = NPC.config[v.ai1].gfxwidth
			if contentsWidth == 0 then
				contentsWidth = NPC.config[v.ai1].width
			end
			local contentsHeight = NPC.config[v.ai1].gfxheight
			if contentsHeight == 0 then
				contentsHeight = NPC.config[v.ai1].height
			end
			local drawX = v.x + 0.5 * v.width - 0.5 * contentsWidth
			local drawY = v.y + 0.5 * v.height - 0.5 * contentsHeight
			
			Graphics.draw{
				x = drawX,
				y = drawY,
				type = RTYPE_IMAGE,
				sceneCoords = true,
				priority = -44, --Above the Card (and all other regular NPCs), but below everything normally above NPCs.
				image = data.revealImage,
				sourceX = 0,
				sourceY = 0,
				sourceWidth = contentsWidth,
				sourceHeight = contentsHeight
			}
		end		
	elseif data.cardAIState == STATE_RETURN then
		if v.animationFrame >= configFile.frames - 4 then
			v.animationFrame = configFile.frames - 5
		end
	end
end
	
return card
