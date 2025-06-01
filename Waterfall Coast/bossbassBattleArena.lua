local bossbass = {}
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local bossbassIDMap = {}

local sharedSettings = {
	--Sprite size
	gfxheight = 64,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 5,
	framestyle = 1,
	framespeed = 6, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 6,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.
	staticdirection = true,
	
	luahandlesspeed = true,
	nohurt=true,
	nogravity = false,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	swimframes=2,
	jumpframes=2,

    canjump = true,
    followsplayer = true,

	hitboxoffsettop = 8,
	hitboxheight = 8,
	jumpboxwidth = 100,
	jumpboxheight = 180,
	jumpboxtop = -140,

	alwayseats = false,
	eatingkillsplayer = true,
	jumpspeedx = 3,
	jumpspeedy = 7.5,

	eatenplayerejectforce = 20,
	eatsound = 55, -- can be number or string
	eattimer = 20,
}

function bossbass.register(id, npcSettings)
    if not bossbassIDMap[id] then
        bossbassIDMap[id] = true
        npcManager.setNpcSettings(table.join(npcSettings, sharedSettings))
        npcManager.registerEvent(id, bossbass, "onTickEndNPC")
        npcManager.registerEvent(id, bossbass, "onDrawNPC")
    end
end
registerEvent(bossbass, "onPostNPCKill")
registerEvent(bossbass, "onNPCTransform")

local function updateHome(v, data)
	local candidate = nil
	for k,w in ipairs(Liquid.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		if not w.isHidden then
			candidate = w
			break
		end
	end
	data.spawnPos = data.spawnPos or v.y

	if candidate ~= nil then
		if candidate ~= data.spawnWaterBox then
			data.spawnPos = v.y
			data.spawnWaterBox = candidate
		elseif data.spawnPos - v.y > v.height then
			data.spawnPos = v.y
		end
	end
end

local function respawnRoutine(t)
	Routine.waitFrames(t.timer)
	local spawn = false
	local s = Section.getActiveIndices()
	for k,sec in ipairs(s) do
		if sec == t.section then
			spawn = true
			break
		end
	end
	if spawn then
		local closestCam = nil
		for k,c in ipairs(Camera.get()) do
			if closestCam == nil or (c.x + 0.5 * c.width - t.x < closestCam.x + 0.5 * closestCam.width - t.x) then
				closestCam = c
			end
		end
		if closestCam ~= nil then
			local mult = 1
			if closestCam.x + 0.5 * closestCam.width > t.x then
				mult = -1
			end

			if closestCam.y + closestCam.height < t.y or closestCam.y > t.y then
				y = closestCam.y - 96
			end
			
			local n = NPC.spawn(t.npcID, closestCam.x + 0.5 * closestCam.width + (0.5 * closestCam.width + NPC.config[t.npcID].width) * mult, t.y, t.section, t.respawns, true)
			n.data._settings.timer = t.timer
			n.data._settings.respawn = true
			n.friendly = t.friendly
			n.dontMove = t.dontMove
			n.layerName = t.layerName
			n.attachedLayerName = t.attachedLayerName
			n.activateEventName = t.activateEventName
			n.deathEventName = t.deathEventName
			n.talkEventName = t.talkEventName
			n.noMoreObjInLayer = t.noMoreObjInLayer
			n.msg = t.msg
		end
	end
end

function bossbass.onNPCTransform(v, oldID)
	if bossbassIDMap[oldID] then
		local data = v.data._basegame
		if data.eatenPlayer > 0 then
			local p = Player(data.eatenPlayer)
			p.forcedState = 0
			data.eatenPlayer = 0
			p.x = v.x + 0.5 * v.width - 0.5 * p.width
			p.y = v.y + 0.5 * v.height - 0.5 * p.height
			p.speedX = 0
			p.speedY = 0
			SFX.play(38)
			if #Colliders.getColliding{
				a = p, b = Block.SOLID .. Block.PLAYERSOLID, btype = Colliders.BLOCK, collisionGroup = v.collisionGroup, filter = function(other)
					return (not other.isHidden) and (not other:mem(0x5A, FIELD_BOOL))
				end } > 0 then
					p:kill()
			end
		end
	end
end

function bossbass.onPostNPCKill(v, r)
	if bossbassIDMap[v.id] then
		if v.data._settings.respawn then
			Routine.run(respawnRoutine, {
				npcID = v.id,
				x = v.x + 0.5 * v.width,
				y = v.y + 0.5 * v.height,
				section = v.section,
				timer = v.data._settings.timer,
				respawns = v.spawnid ~= 0,
				friendly = v.friendly,
				dontMove = v.dontMove,
				layerName = v.layerName,
				attachedLayerName = v.attachedLayerName,
				activateEventName = v.activateEventName,
				deathEventName = v.deathEventName,
				talkEventName = v.talkEventName,
				noMoreObjInLayer = v.noMoreObjInLayer,
				msg = v.msg
			})
		end

		local data = v.data._basegame
		if data.eatenPlayer ~= nil and data.eatenPlayer > 0 then
			local p = Player(data.eatenPlayer)
			p.forcedState = 0
			data.eatenPlayer = 0
			p.speedX = 0
			p.speedY = 0
			SFX.play(38)
			if #Colliders.getColliding{
				a = p, b = Block.SOLID .. Block.PLAYERSOLID, btype = Colliders.BLOCK, collisionGroup = v.collisionGroup, filter = function(other)
					return (not other.isHidden) and (not other:mem(0x5A, FIELD_BOOL))
				end } > 0 then
					p:kill()
			end
		end
	end
end

local function eatNPCs(v)
	local data = v.data._basegame
	local cfg = NPC.config[v.id]
	for k,n in ipairs(
		Colliders.getColliding{
			a = v, 
			b = NPC.HITTABLE,
			btype = Colliders.NPC,
			collisionGroup = v.collisionGroup,
			filter = function(other) return other ~= v and not NPC.config[other.id].noyoshi and not other.friendly end
		}) do

			if type(cfg.eatsound) == "string" then
				SFX.play(Misc.resolveSoundFile(cfg.eatsound))
			else
				SFX.play(cfg.eatsound)
			end
			n:kill(9)
			data.eatTimer = cfg.eattimer
		end
end

function bossbass.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	local cfg = NPC.config[v.id]

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.eatTimer = 0
		data.eatenPlayer = 0
		data.wasHeld = false

		data.state = 0
		data.timer = 40
		data.eatenx = 0
		data.eateny = 0
		data.eatenAnimCooldown = 0

		data.wasUnderwater = true
		data.hasDipped = true
		updateHome(v, data)
	end

	if v:mem(0x138, FIELD_WORD) > 0 then
		return
	end

	
	if v:mem(0x12C, FIELD_WORD) > 0 then
		data.eatTimer = data.eatTimer or 0
		data.wasHeld = true

		if data.eatTimer > 0 then
			data.eatTimer = data.eatTimer - 1
		else
			eatNPCs(v)
		end
		return
	end

	if data.wasHeld then
		v:kill(4)
		return
	end
	
	data.timer = data.timer + 1
	
	if data.state == 0 then
        if cfg.followsplayer then
            local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
            if p.x < v.x + 0.5 * v.width - 280 then
                v.direction = -1
            elseif p.x > v.x + 0.5 * v.height + 280 then
                v.direction = 1
            end
        else
            -- use redirectors
            for k,b in BGO.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
                if not b.isHidden then
                    if b.id == 194 then
                        v.direction = 1
                    elseif b.id == 193 then
                        v.direction = -1
                    end
                end
            end
        end
		
		v.speedX = math.clamp(v.speedX + .5 * v.direction, -cfg.speed, cfg.speed)
		v.speedY = v.speedY - (v.y - data.spawnPos) * 0.1
		if v.speedY > 0 then
			data.hasDipped = true
		elseif v.speedY < 0 and data.hasDipped and v.y < data.spawnPos then
			v.speedY = 0
			v.y = data.spawnPos
		end

		if not cfg.nogravity then
			v.speedY = v.speedY - Defines.npc_grav
		end

		if (data.timer >= 40 and (not v.friendly) and data.eatenPlayer == 0) then
            local doJump = (not cfg.nogravity and not v.underwater)

            if cfg.canjump and not doJump then
                for k,p in ipairs(Player.get()) do
                    if math.abs(v.x + 0.5 * v.width - 0.5 * cfg.jumpboxwidth - p.x) <= cfg.jumpboxwidth and math.abs(v.y + cfg.jumpboxtop - p.y) <= cfg.jumpboxheight then
                        doJump = true
                        break
                    end
                end
            end

            if doJump then
                if v:mem(0x136, FIELD_BOOL) == false then
                    v.speedY = -cfg.jumpspeedy
                end
    
                data.timer = 0
                data.state = 1
                data.hasDipped = false
            end
		end
	elseif data.state == 1 then
		if cfg.nogravity then
			v.speedY = v.speedY + Defines.npc_grav
		end
		if v:mem(0x136, FIELD_BOOL) == false then
			v.speedX = cfg.jumpspeedx * v.direction
		end
		if (v.underwater and not data.wasUnderwater) or (v.y >= data.spawnPos and (v.underwater or cfg.nogravity)) then
			data.timer = 0
			data.state = 0
		end
	end

	if not cfg.nogravity and data.wasUnderwater ~= v.underwater then
		updateHome(v, data)
	end

	if v.underwater and data.spawnWaterBox then
		local layer = data.spawnWaterBox.layer
		if layer and not layer:isPaused() then
			v.x = v.x + layer.speedX
			v.y = v.y + layer.speedY
			data.spawnPos = data.spawnPos + layer.speedY
		end
	elseif cfg.nogravity and data.state == 0 then
		utils.applyLayerMovement(v)
	end
	
	--Eating behavior
	if data.eatenPlayer == 0 and (cfg.alwayseats or v.friendly or data.state == 1) then
		if v.friendly then
			
			data.eatTimer = data.eatTimer or 0

			if data.eatTimer > 0 then
				data.eatTimer = data.eatTimer - 1
			else
				eatNPCs(v)
			end
		elseif cfg.nohurt and Level.winState() == 0 and data.eatenAnimCooldown <= 0 then
			for k,p in ipairs(Player.get()) do
				if Colliders.collide(p,v) and math.abs(v.y + cfg.hitboxoffsettop - p.y) <= cfg.hitboxheight then
					if p.forcedState == 0 and not p.inClearPipe and not p.inLaunchBarrel and not p:isInvincible() and p.hasStarman == false and p.isMega == false and p.deathTimer == 0 then
						data.eatenPlayer = p.idx
						data.eatenx = p.x
						data.eateny = p.y
						if p.holdingNPC and p.holdingNPC.isValid then
							p.holdingNPC.heldIndex = 0
						end
	
						if type(cfg.eatsound) == "string" then
							SFX.play(Misc.resolveSoundFile(cfg.eatsound))
						else
							SFX.play(cfg.eatsound)
						end
					end
				end
			end
		end
	end
	
	if data.eatenPlayer > 0 then
		local p = Player(data.eatenPlayer)
		p.forcedState = FORCEDSTATE_BOSSBASS
		p.frame = -50 * p.direction
		p:mem(0x140, FIELD_WORD, 2)
		if cfg.eatingkillsplayer then
			p.x = data.eatenx
			p.y = data.eateny

			data.eatTimer = data.eatTimer + 1
			if data.eatTimer == 65 then
				Player(data.eatenPlayer):kill()
				for k,w in ipairs(Effect.get({3, 5, 129, 130, 134, 149, 150, 151, 152, 153, 154, 155, 156, 159, 161})) do
					w.timer = 0
					w.animationFrame = -1000
				end
				data.eatenPlayer = 0
				data.eatTimer = 0
			end
		else
			p.x = v.x + 0.5 * v.width
			p.y = v.y + v.height - p.height
			data.eatenAnimCooldown = 64
			if p.keys.jump == KEYS_PRESSED and #Colliders.getColliding{
				a = p, b = Block.SOLID .. Block.PLAYERSOLID, btype = Colliders.BLOCK, collisionGroup = v.collisionGroup, filter = function(other)
					return (not other.isHidden) and (not other:mem(0x5A, FIELD_BOOL))
				end } == 0 then
				p.forcedState = 0
				p:mem(0x11C, FIELD_WORD, cfg.eatenplayerejectforce)
				data.eatenPlayer = 0
				SFX.play(38)
			end
		end
	end

	data.eatenAnimCooldown = data.eatenAnimCooldown - 1
	data.wasUnderwater = v.underwater
end

function bossbass.onDrawNPC(v)
	if v.despawnTimer <= 0 then return end

	local cfg = NPC.config[v.id]
	local data = v.data._basegame
	utils.restoreAnimation(v)

	local frameset = 0

	if not data.initialized then
		return
	end

	if v:mem(0x12C, FIELD_WORD) > 0 or v.friendly or cfg.alwayseats or data.eatenAnimCooldown > 0 then
		if data.eatTimer <= 0 and (cfg.eatingkillsplayer or data.eatenPlayer == 0) then
			frameset = 1
		end
	else
		if data.state == 0 then
			if v.speedY > 0 then
				frameset = 2
			end
		elseif data.state == 1 then
			if data.eatenPlayer == 0 then
				frameset = 1
			end
		end
	end

	if frameset == 0 then
		v.animationFrame = utils.getFrameByFramestyle(v, {
			frames = cfg.swimframes,
			gap = cfg.frames - cfg.swimframes,
			offset = 0
		})
	elseif frameset == 1 then
		v.animationFrame = utils.getFrameByFramestyle(v, {
			frames = cfg.jumpframes,
			gap = cfg.frames - cfg.swimframes - cfg.jumpframes,
			offset = cfg.swimframes
		})
	else
		v.animationFrame = utils.getFrameByFramestyle(v, {
			frames = cfg.frames - cfg.swimframes - cfg.jumpframes,
			gap = 0,
			offset = cfg.swimframes + cfg.jumpframes
		})
	end
end

return bossbass