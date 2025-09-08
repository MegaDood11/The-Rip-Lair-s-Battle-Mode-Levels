local smwfuzzy = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

-- settings
local config = {
	id = npcID, 
	gfxoffsetx = 0, 
	gfxoffsety = 0, 
	width = 32, 
    height = 32,
    gfxwidth = 32,
    gfxheight = 32,
    frames = 5,
    framestyle = 0,
    framespeed = 4,
    nofireball = true,
    noiceball = true,
    nogravity = true,
    jumphurt = true,
    spinjumpsafe = false,
    noblockcollision = true,
    noyoshi = true,
    effectid = npcID
}

npcManager.setNpcSettings(config)

function smwfuzzy.onInitAPI()
    npcManager.registerEvent(npcID, smwfuzzy, "onTickEndNPC")
end

function smwfuzzy.onTickEndNPC(v)
    if Defines.levelFreeze then return end
    if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 then
        v.data.radius = v.data._settings.radius or 96
        v.data.speed = v.data._settings.speed or 3
        v.data.startangle = v.data._settings.startangle or 0
        v.data.angle = v.data.startangle or 0
		return
    end

    if v.data.pivot == nil then
        v.data.pivot = vector(v:mem(0xA8, FIELD_DFLOAT), v:mem(0xB0, FIELD_DFLOAT))
        v.data.radius = v.data._settings.radius or 96
        v.data.speed = v.data._settings.speed or 3
        v.data.startangle = v.data._settings.startangle or 0
        v.data.angle = v.data.startangle
        v.data.direction = v.direction
    end

    if not Layer.isPaused() then
        v.data.pivot.x = v.data.pivot.x + v.layerObj.speedX
        v.data.pivot.y = v.data.pivot.y + v.layerObj.speedY
    end

    local v0 = vector(0, v.data.radius):rotate(v.data.angle)
    v.x = v.data.pivot.x + v0.x
    v.y = v.data.pivot.y + v0.y

    v.data.angle = (v.data.angle + v.data.speed * v.data.direction) % 360

    if lunatime.tick() % math.max(math.ceil(math.abs(4 - 0.5 * v.data.speed)), 1) == 0 then
        Effect.spawn(NPC.config[v.id].effectid, v.x, v.y)
    end

    local v1 = v.data.pivot + vector(0, v.data.radius):rotate(v.data.angle)
    v.direction = -1
    v.speedX = v1.x - v.x
    v.speedY = v1.y - v.y
end

return smwfuzzy