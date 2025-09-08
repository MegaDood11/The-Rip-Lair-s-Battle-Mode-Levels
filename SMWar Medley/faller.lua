--[[
    by Marioman2007
    version 1.0
]]

local faller = {}

faller.enabled = true
faller.fallDistance = 8
faller.climbingCooldown = 16

faller.input = function(p)
    return p.keys.altJump == KEYS_PRESSED and p.keys.down
end


local cantThisFrame = {}
local climbingCooldown = {}

local impassableBlocks = {}
local passableBlocks = {}

local impassableNPCs = {}
local passableNPCs = {}

local aw
pcall(function() aw = require("anotherwalljump") end)
pcall(function() aw = aw or require("aw") end)

local GP
pcall(function() GP = require("GroundPound") end)

local function isOnGround(p)
	return (
		(p.speedY == 0) -- "on a block"
		or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
		or (p:mem(0x48,FIELD_WORD) ~= 0) -- on a slope
	)
end

local function canFallThrough(p)
    return (
        faller.enabled
		and not p.inLaunchBarrel
		and not p.inClearPipe
        and not cantThisFrame[p.idx]
		and (not aw or aw.isWallSliding(p) == 0)
		and (not GP or not GP.isPounding(p))
		and isOnGround(p)
		and p.forcedState == FORCEDSTATE_NONE
		and p.deathTimer == 0 and not p:mem(0x13C, FIELD_BOOL) -- not dead
		and p.mount ~= MOUNT_CLOWNCAR
		and not p.isMega
		and not p:mem(0x0C, FIELD_BOOL) -- fairy
		and not p:mem(0x3C, FIELD_BOOL) -- sliding
		and not p:mem(0x44, FIELD_BOOL) -- surfing on a rainbow shell
		and not p:mem(0x4A, FIELD_BOOL) -- statue
		and p:mem(0x26,FIELD_WORD) == 0 -- picking up something from the top
		and Level.endState() == LEVEL_WIN_TYPE_NONE
	)
end

local function npcFilter(v, p)
    if passableNPCs[v.id] then
        return false
    end

    local config = NPC.config[v.id]

    return Misc.canCollideWith(v, p) and (
        impassableNPCs[v.id]
        or config.playerblock
        or config.playerblocktop
    )
end

local function fallDown(p)
    local col = Colliders.Box(p.x, p.y + p.height, p.width, faller.fallDistance)
    local ref = nil

    for k, v in ipairs(Colliders.getColliding{a = col, btype = Colliders.NPC}) do
        if npcFilter(v, p) then
            return
        end
    end

    for k, v in ipairs(Colliders.getColliding{a = col, btype = Colliders.BLOCK}) do
        if impassableBlocks[v.id] then
            return
        end

        if passableBlocks[v.id] or (not Block.SOLID_MAP[v.id] and not Block.PLAYERSOLID_MAP[v.id]) then
            ref = v
        else
            ref = nil
        end
    end

    if ref ~= nil then
        p.y = p.y + faller.fallDistance
        p:mem(0x11E, FIELD_BOOL, false)
        p:mem(0x120, FIELD_BOOL, false)
        climbingCooldown[p.idx] = faller.climbingCooldown
    end
end


function faller.preventFalling(p)
    cantThisFrame[p.idx] = true
end

function faller.addPassableBlock(id)
    impassableBlocks[id] = nil
    passableBlocks[id] = true
end

function faller.addImpassableBlock(id)
    impassableBlocks[id] = true
    passableBlocks[id] = nil
end

function faller.addPassableNPC(id)
    impassableNPCs[id] = nil
    passableNPCs[id] = true
end

function faller.addImpassableNPC(id)
    impassableNPCs[id] = true
    passableNPCs[id] = nil
end

function faller.onInitAPI()
	registerEvent(faller, "onTick")
end

function faller.onTick()
	for _, p in ipairs(Player.get()) do
        if climbingCooldown[p.idx] == nil then
            climbingCooldown[p.idx] = 0

        elseif climbingCooldown[p.idx] > 0 then
            climbingCooldown[p.idx] = climbingCooldown[p.idx] - 1

            p:mem(0x40, FIELD_WORD, 0)
            p:mem(0x2C, FIELD_DFLOAT, 0)
        end

        if canFallThrough(p) and faller.input(p) then
            fallDown(p)
        end

        cantThisFrame[p.idx] = nil
	end
end

return faller