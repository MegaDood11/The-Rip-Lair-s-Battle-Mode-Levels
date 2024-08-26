local npcManager = require("npcManager")

local leaper = {}

local onlinePlayNPC = require("scripts/onlinePlay_npc")

local NPCConfigSpeedCache = {}

function leaper.register(id)
    npcManager.registerEvent(id, leaper, "onTickNPC")
    npcManager.registerEvent(id, leaper, "onDrawEndNPC")
    NPC.config[id].nowaterphysics = true
    NPC.config[id].nogravity = true
    NPCConfigSpeedCache[id] = NPCConfigSpeedCache[id] or NPC.config[id].speed
    NPC.config[id].speed = 1
end

leaper.DIR = {
    DOWN = "down",
    UP = "up",
    LEFT = "left",
    RIGHT = "right"
}

leaper.TYPE = {
    WATER = "water",
    LAVA = "lava",
    SECTION = "section",
    FIXED = "fixed"
}

leaper.STATE = {
    FALLING = 1,
    RESTING = 2,
    RISING = 3
}

local leaperdata = {"down", "type", "resttime", "gravitymultiplier", "jumpspeed", "effect", "sound"}
local leaperdowns = {leaper.DIR.DOWN, leaper.DIR.LEFT, leaper.DIR.RIGHT, leaper.DIR.UP}
local leapertypes = {leaper.TYPE.WATER, leaper.TYPE.LAVA, leaper.TYPE.SECTION, leaper.TYPE.FIXED}
local leapersettings = {"useFixed", "jumpHeight", "turns"}

local defaultLeaperData = {
    down = leaper.DIR.DOWN,
    type = leaper.TYPE.WATER,
    resttime = 65,
    gravitymultiplier = 1,
    jumpspeed = 8,
    effect = 0,
    sound = 0,
    friendlyrest = false
}

local defaultLeaperSettings = {
    turns = false,
    useFixed = false,
    jumpHeight = 250
}

local gravityManipulators = {
    [leaper.DIR.DOWN] = {bounds = "bottom", coordinate = "y", scale = "height", scaleMult = 0},
    [leaper.DIR.UP] = {bounds = "top", coordinate = "y", scale = "height", scaleMult = 1},
    [leaper.DIR.LEFT] = {bounds = "left", coordinate = "x", scale = "width", scaleMult = 1},
    [leaper.DIR.RIGHT] = {bounds = "right", coordinate = "x", scale = "width", scaleMult = 0},
}

local function conditionalGt(a, b, gt)
    if gt then
        return a > b
    else
        return a < b
    end
end

local function getOverlappingBoundFixed(v, data, top, dir)
    return conditionalGt(data.fixedBound, top - 32 * dir, dir < 0)
end

local function getOverlappingBoundWater(v, data, top, dir)
    local waters = Liquid.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)
    local manip = gravityManipulators[data.down]
    for k,w in ipairs(waters) do
		if not w.isHidden then
			local y = w[manip.coordinate]
			y = y + w[manip.scale] * manip.scaleMult - 32 * dir
			if conditionalGt(y, top - 32 * dir, dir < 0) then
				return true
			end
		end
    end
    return false
end

local function getOverlappingBoundLava(v, data, top, dir)
    local manip = gravityManipulators[data.down]
    for k,w in Block.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
        if Block.LAVA_MAP[w.id] and not (w.isHidden or w:mem(0x5A, FIELD_BOOL)) then
            local y = w[manip.coordinate]
            y = y + w[manip.scale] * 0.5
            if conditionalGt(y, top, dir < 0) then
                return true
            end
        end
    end
    return false
end

local function getOverlappingBoundSection(v, data, top, dir)
    return conditionalGt(data.section.boundary[gravityManipulators[data.down].bounds], top - 32 * dir, dir < 0)
end

local getIsOverlappingBound = {
    [leaper.TYPE.FIXED] = getOverlappingBoundFixed,
    [leaper.TYPE.WATER] = getOverlappingBoundWater,
    [leaper.TYPE.LAVA] = getOverlappingBoundLava,
    [leaper.TYPE.SECTION] = getOverlappingBoundSection
}

local function reset(v)
    local data = v.data._basegame
    local settings = v.data._settings
    data.restTimer = 0
    data.state = leaper.STATE.FALLING
    data.wasThrown = false
    if settings.useFixed then
        data.type = leaper.TYPE.FIXED
    end
    data.hasLandedOnce = false
    --Fixed type? This is the rest point reference. Else? This is the upper bound.
    data.fixedBound = nil
end

local function init(v)
    local data = v.data._basegame
    for k,d in ipairs(leaperdata) do
        data[d] = NPC.config[v.id][d]
        if data[d] == nil then
            data[d] = defaultLeaperData[d]
        end
    end
    local settings = v.data._settings
    for k,d in ipairs(leapersettings) do
        if settings[d] == nil then
            settings[d] = defaultLeaperSettings[d]
        end
    end
    data.speed = NPCConfigSpeedCache[v.id] or 0
    data.section = Section(v:mem(0x146, FIELD_WORD))
    data.fixedBoundAnchor = nil
    data.friendly = v.friendly
    data.direction = v.direction
    reset(v)
    data.init = true
end

--Switch variables based on gravity direction
local function switchXY(data, x, y)
    local speedX, speedY = "speedX", "speedY"
    local width, height = "width", "height"
    local dir = 1

    if data.down == leaper.DIR.LEFT or data.down == leaper.DIR.RIGHT then
        x, y = y, x
        speedX, speedY = speedY, speedX
        width, height = height, width
    end

    if data.down == leaper.DIR.LEFT or data.down == leaper.DIR.UP then
        dir = -1
    end
    return x, y, width, height, speedX, speedY, dir
end

local function shouldStopRising(top, dir, data, height)
    local limit = data.fixedBound
    local s = math.abs(data.jumpspeed)
    local anticipationTime = (s * s) / (2 * Defines.npc_grav * data.gravitymultiplier)
    if data.type == leaper.TYPE.FIXED then
        limit = limit + (height - anticipationTime) * -dir
    else
        limit = limit + anticipationTime * dir
    end

    return conditionalGt(top, limit, dir < 0)
end

local function returnedToHome(v, data, top, dir)
    return getIsOverlappingBound[data.type](v, data, top, dir)
end

local function playSoundAndEffect(v, data)
    if data.effect > 0 then
        local xMod = 1
        local yMod = 1
        if data.down == leaper.DIR.LEFT then
            xMod = -1
        elseif data.down == leaper.DIR.DOWN then
            yMod = -1
        end
        Effect.spawn(data.effect, v.x + 0.5 * v.width, v.y - 0.5 * v.height + (0.5 * v.height + 32) * yMod)
    end

    if data.sound > 0 then
        SFX.play(data.sound)
    end
end

function leaper.onTickNPC(v)
	if Defines.levelFreeze then
		return
    end
    
    local data = v.data._basegame

	if v:mem(0x12A, FIELD_WORD) <= 0 then
		reset(v)
		return
    end

    if v:mem(0x138, FIELD_WORD) > 0 then
        return
    end

    if not data.init then
        init(v)
    end
    
    local x, y, width, height, speedX, speedY, dir = switchXY(data, "x", "y")

    local center = vector.v2(v[x] + 0.5 * v[width], v[y] + 0.5 * v[height])
    --Alright fellas, let's get this RECT
    local left = center.x + 0.5 * v[width] * -dir
    local right = center.x + 0.5 * v[width] * dir
    local top = center.y + 0.5 * v[height] * -dir
    local bottom = center.y + 0.5 * v[height] * dir

    if data.fixedBound == nil then
        if data.type == leaper.TYPE.FIXED then
            data.fixedBound = bottom
        else
            data.fixedBound = top
        end
        data.fixedBoundAnchor = data.fixedBound
    end

    local settings = v.data._settings
	-- Reset top y if respawning
	if  v:mem(0x124, FIELD_WORD) == 0  then
		data.topY = spawnY
	end

	-- Manage movement
	local isHeld = (v:mem(0x12C,FIELD_WORD) ~= 0)
    local isThrown = v:mem(0x136,FIELD_BOOL)
    
    if v.dontMove then
        v.dontMove = false
        data.dontMove = true
    end

	if  isHeld  then
        data.state = leaper.STATE.FALLING
        if data.type ~= leaper.TYPE.FIXED then
            data.fixedBound = top
        end
	end

	if  not isThrown  and  data.wasThrown  then  -- if just recovered from being thrown
		data.topY = v.y
        if data.type ~= leaper.TYPE.FIXED then
            data.fixedBound = top
        end
	end

	if  not isHeld  and  not isThrown  then  -- if not being held or thrown
        if  data.state == leaper.STATE.RESTING  then
            data.restTimer = data.restTimer + 1

            local cfg = NPC.config[v.id].friendlyrest
            if cfg then
                v.friendly = true
            end
            if data.restTimer >= data.resttime then
                data.restTimer = 0
                data.state = leaper.STATE.RISING
                if data.hasLandedOnce and settings.turns then
                    data.direction = -data.direction
                end
                data.hasLandedOnce = true
                if cfg then
                    v.friendly = data.friendly
                end
                playSoundAndEffect(v, data)
            end
            v[speedY] = 0
        else
            v[speedY] = v[speedY] + Defines.npc_grav * dir * data.gravitymultiplier

            if data.hasLandedOnce and not data.dontMove then
                v[speedX] = data.direction * data.speed
            end

            if data.state == leaper.STATE.FALLING then
                if conditionalGt(v[speedY], 0, dir > 0) and returnedToHome(v, data, top, dir) then
                    data.state = leaper.STATE.RESTING
                    v[speedY] = 0
                    playSoundAndEffect(v, data)
                end
            else
                v[speedY] = math.abs(data.jumpspeed) * -dir
                if shouldStopRising(top, dir, data, settings.jumpHeight) then
                    data.state = leaper.STATE.FALLING
                end
            end
		end
    elseif isThrown then
        v[speedY] = v[speedY] + Defines.npc_grav * dir * data.gravitymultiplier
    end
	local lspdx = 0
	local lspdy = 0
	local layer = v.layerObj
	if layer and not layer:isPaused() then
		lspdx = layer.speedX
		lspdy = layer.speedY
        data.fixedBound = data.fixedBound + layer[speedY]
        data.fixedBoundAnchor = data.fixedBoundAnchor + layer[speedY]
	end
	v.x = v.x + lspdx
	v.y = v.y + lspdy
	data.wasThrown = isThrown
end

function leaper.onDrawEndNPC(v)
    local data = v.data._basegame
    if data.dontMove ~= nil then
        v.dontMove = data.dontMove
        data.dontMove = nil
    end
end

onlinePlayNPC.onlineHandlingConfig[459] = {
	getExtraData = function(v)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		return {
			down = data.down,
			type = data.type,
			resttime = data.resttime,
			gravitymultiplier = data.gravitymultiplier,
			jumpspeed = data.jumpspeed,
			effect = data.effect,
			sound = data.sound,
			friendlyrest = data.friendlyrest,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		data.down = receivedData.down
		data.type = receivedData.type
		data.resttime = receivedData.resttime
		data.gravitymultiplier = receivedData.gravitymultiplier
		data.jumpspeed = receivedData.jumpspeed
		data.effect = receivedData.effect
		data.sound = receivedData.sound
		data.friendlyrest = receivedData.friendlyrest
	end,
}

onlinePlayNPC.onlineHandlingConfig[460] = {
	getExtraData = function(v)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		return {
			down = data.down,
			type = data.type,
			resttime = data.resttime,
			gravitymultiplier = data.gravitymultiplier,
			jumpspeed = data.jumpspeed,
			effect = data.effect,
			sound = data.sound,
			friendlyrest = data.friendlyrest,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		data.down = receivedData.down
		data.type = receivedData.type
		data.resttime = receivedData.resttime
		data.gravitymultiplier = receivedData.gravitymultiplier
		data.jumpspeed = receivedData.jumpspeed
		data.effect = receivedData.effect
		data.sound = receivedData.sound
		data.friendlyrest = receivedData.friendlyrest
	end,
}

return leaper