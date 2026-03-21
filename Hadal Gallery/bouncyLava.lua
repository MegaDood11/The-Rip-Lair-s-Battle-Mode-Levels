---------------------------------------------------------------
--[[      bouncyLava.lua v1.5.0 by rixitic & KBM-Quine     ]]--
--[[                 this is provided AS-IS                ]]--
--[[ and will likely see few updates (maybe after beta 5?) ]]--
---------------------------------------------------------------

local bouncyLava = {
    -- library only vars
	enabled = true, -- basic flip switch for functionality
	zoneBlockID = 755, -- block id considered for zone checks
    launchTime = 55, -- amount a control lock timer is set to upon launch
	sectionConfig = {}, -- stores per-section settings

	-- setting shared with per-section configs
	enabledOverride = false, -- overrides enabled. useful for making specifc sections force bouncyLava
	onlyZones = false, -- makes lava processing only run for bouncy zones

	-- settings shared with per-zone & per-section configs
	strength = 13.5, -- strength of a bounce after falling in lava 
    slopeStrengthModifier = 0.6, -- modifier for strength when bouncing off a slope
	respectsMercy = true, -- whether or not harming or killing is done during invulnerability frames
	canHarm = true, -- whether or not harm is called on bounce
	canKill = true, -- whether or not the player is killed when small

}

-- Helper function; dummies out table for section settings to avoid nil entry access
local function initSection(id)
	bouncyLava.sectionConfig[id] = bouncyLava.sectionConfig[id]  or  {}
end

-- set up settings for section specified
-- sets the config specified in props to the value given
-- if props is otherwise a table, fills the section config with that table
function bouncyLava.configureSection(sectionID, props, value)
    if (sectionID == nil or type(sectionID) ~= "number" or sectionID ~= math.floor(sectionID) or (sectionID < 0 or sectionID > 20)) then error('nil, non-number, or invalid section "' .. sectionID .. '" supplied', 1) end
	initSection(sectionID)
	local tbl = bouncyLava.sectionConfig[sectionID]

	if  type(props) == "string"  and  value ~= nil  then
		tbl[props] = value
	else
		for  k,v in pairs(props)  do
			tbl[k] = v
		end
	end
end

-- figure out which config to use. zones & setting are optional. 
-- without zones supplied, it skips checking the zones' settings.
-- without the setting supplied, it returns the sections' settings
function bouncyLava.getConfig(sectionId, setting, zones)
	if  sectionId == nil  or  sectionId == -1  then
		sectionId = player.section
	end

	initSection(sectionId)
	if (zones ~= nil  and  #zones > 0 and zones[1].data._settings[setting] ~= nil) then
		return zones[1].data._settings[setting]
	elseif (setting ~= nil and bouncyLava.sectionConfig[sectionId][setting] ~= nil) then
		return bouncyLava.sectionConfig[sectionId][setting]
	elseif (setting ~= nil and bouncyLava[setting] ~= nil) then
		return bouncyLava[setting]
	elseif setting == nil then
		return bouncyLava.sectionConfig[sectionId]
	end
end

-- localized table commands; overall more perfomant this way
local tableinsert = table.insert
local tableremove = table.remove

-- gets lava blocks surrounding player specified within a 2 pixel margin
local function getAdjacentLava(playerObj)
	local pRect = {x1=playerObj.x-2, y1=playerObj.y-2, x2=playerObj.x+playerObj.width+2, y2=playerObj.y+playerObj.height+2}

	local lavaBlocks = {}
	for k,v in Block.iterateIntersecting(pRect.x1, pRect.y1, pRect.x2, pRect.y2) do
		if  table.icontains(Block.LAVA,v.id)  then
			tableinsert(lavaBlocks, v)
		end
	end

	return lavaBlocks;
end

-- setup constants so we can actually tell what's what
SIDE_NONE = 0
SIDE_TOP = 1
SIDE_RIGHT = 2
SIDE_BOTTOM = 3
SIDE_LEFT = 4
SIDE_IN = 5
SIDE_SLOPE = 6

-- checks blocks supplied for slope configs
local function checkSlope(blockObj, side)
	if (Block.config[blockObj.id].floorslope ~= 0 or Block.config[blockObj.id].ceilingslope ~= 0) and side ~= 0 then
        side = SIDE_SLOPE
    end
    return side
end

-- checks blocks supplied for distance from player supplied
local function getClosest(playerObj, table)
    local closest = {
        object = table[1],
        distance = 100000
    }
    local pMid = vector(playerObj.x + 0.5*playerObj.width, playerObj.y + 0.5*playerObj.height)
	for  _,v in ipairs(table)  do
        local bMid = vector(v.x + 0.5*v.width, v.y + 0.5*v.height)
        local distance = math.sqrt((pMid.x-bMid.x)^2 + (pMid.y-bMid.y)^2)
        if math.abs(distance) < closest.distance then
            closest.object = v
            closest.distance = distance
        end
	end
    return closest.object
end

-- check for block, and move player if inside
local function checkForBlock(playerObj, blockObj, toCulprit)
    for k,v in Block.iterateIntersecting(playerObj.x, playerObj.y, playerObj.x+playerObj.width, playerObj.y+playerObj.height) do
        if v ~= blockObj and not (Block.config[v.id].semisolid or Block.config[v.id].sizable or Block.config[v.id].passthrough) then
            -- we're in a block, so let's get out
            
            local hpMid = vector(playerObj.x + 0.5*playerObj.width, playerObj.y + 0.5*playerObj.height)
            local cMid = vector(v.x + 0.5*v.width, v.y + 0.5*v.height)
            local toCulprit = hpMid-cMid
            local winningSide
            if math.abs(toCulprit.x) > math.abs(toCulprit.y) then
                if math.sign(toCulprit.x) == -1 then
                    winningSide = 2
                else
                    winningSide = 4
                end
            else
                if math.sign(toCulprit.y) == -1 then
                    winningSide = 1
                else
                    winningSide = 3
                end
            end
            -- set the position so the player ISN'T in the block anymore
            -- vertical
            if winningSide == 1 or winningSide == 3 then
                -- top of block
                if  winningSide == 1  then
                    playerObj.y = v.y - playerObj.height - 2 + blockObj.layerObj.speedY
                -- bottom of block
                else
                    playerObj.y = v.y + v.height + 2 + blockObj.layerObj.speedY
                end
            -- horizontal
            else
                -- right of block
                if  winningSide == 2 then
                    playerObj.x = v.x - playerObj.width - 2 + blockObj.layerObj.speedX
                -- left of block
                else
                    playerObj.x = v.x + v.width + 2 + blockObj.layerObj.speedX
                end
            end
            break
        end
	end
end

function bouncyLava.onInitAPI()
	registerEvent(bouncyLava, "onTick")
	registerEvent(bouncyLava, "onPlayerKill")
end

local pData = {}

function bouncyLava.onTick()
    -- don't bother if we're not in a level
    if  isOverworld  then
		return
	end

    for _, p in ipairs(Player.get()) do
        -- don't bother if the settings aren't enabled
        if  not (bouncyLava.enabled or bouncyLava.getConfig(p.section, "enabledOverride")) then
            return
        end

        -- setup player data
        local harmedPlayer = p
        pData[harmedPlayer.idx] = pData[harmedPlayer.idx] or {launchTimer = 0}
        data = pData[harmedPlayer.idx]

        -- don't continue if the player is already dead
        if harmedPlayer.deathTimer > 0 then return end

        -- if our launch timer is active, unhold the player's run buttons (for speed purposes)
        if data.launchTimer > 0 then
            data.launchTimer = pData[harmedPlayer.idx].launchTimer - 1
            harmedPlayer.keys.run = KEYS_UP
            harmedPlayer.keys.altRun = KEYS_UP
            harmedPlayer:mem(0x160, FIELD_WORD, 2) -- projectile cooldown
            harmedPlayer:mem(0x172, FIELD_BOOL, false) -- run button bool, powerup related
        end

        -- reset the launch timer if we're back on the ground properor start climing
        if (harmedPlayer.speedY == 0 or harmedPlayer:mem(0x176,FIELD_WORD) ~= 0 or harmedPlayer:mem(0x48,FIELD_WORD) ~= 0) then
            data.launchTimer = 0
        end

        -- if there's lava nearby, figure out if we should be dead
        local adjacentLava = getAdjacentLava(harmedPlayer)
        if  #adjacentLava > 0  then
            local culprit = getClosest(harmedPlayer, adjacentLava)
            local culpritSpeed = vector(0,0)
            if  (culprit.layerObj ~= nil)  then
                culpritSpeed.x = culprit.layerObj.speedX
                culpritSpeed.y = culprit.layerObj.speedY
            end

            -- check side before doing anything so we can cancel actions if needed
            local side = culprit:collidesWith(harmedPlayer)
            side = checkSlope(culprit, side)

            -- if we're not actually colliding, then don't bother
            if side == SIDE_NONE then return end

            -- add some pixels so invincible players can still use it
            local collisionAdd = vector(0,0,0,2)
            if Defines.cheat_donthurtme then
                collisionAdd.x = 2 
                collisionAdd.y = 2 
                collisionAdd.z = 4
                collisionAdd.w = 4
            end

            -- if we're not on a moving block, do better collisions. can't do it for moving ones because redigit slopes
            if (culpritSpeed.x == 0 and culpritSpeed.y == 0) then
                if not Colliders.collide(Colliders.Box(harmedPlayer.x-collisionAdd.x, harmedPlayer.y-collisionAdd.y, harmedPlayer.width+collisionAdd.z, harmedPlayer.height+collisionAdd.w), culprit) then return end -- if we're not actually colliding, then don't bother
            end

            -- check that there isn't a block in the lava block. if there is, don't continue
            for k,v in Block.iterateIntersecting(culprit.x, culprit.y, culprit.x+culprit.width, culprit.y+culprit.height) do
                if v ~= culprit and not Block.config[v.id].passthrough and (culpritSpeed.x == 0 and culpritSpeed.y == 0) then
                    if not (harmedPlayer.y + harmedPlayer.height > v.y) then
                        return
                    end
                end
            end

            -- check for zones
            local zones = Colliders.getColliding{a=p, b=bouncyLava.zoneBlockID, btype=Colliders.BLOCK, filter = function(block)
                return (not block.isHidden and not block:mem(0x5A, FIELD_BOOL))
            end}

            if bouncyLava.getConfig(harmedPlayer.section, "onlyZones", zones) and (zones == nil  or  #zones <= 0) then return end -- if only zones should apply and there aren't any, return early

            -- check whether the player should get harmed or die
            if (harmedPlayer:mem(0x140,FIELD_WORD) == 0 and bouncyLava.getConfig(harmedPlayer.section, "respectsMercy", zones))  or  (harmedPlayer.forcedState == FORCEDSTATE_NONE and harmedPlayer:mem(0x140,FIELD_WORD) < 145  and not bouncyLava.getConfig(harmedPlayer.section, "respectsMercy", zones))  then
                if  (harmedPlayer.powerup ~= PLAYER_SMALL or harmedPlayer.mount > 0) and bouncyLava.getConfig(harmedPlayer.section, "canHarm", zones) then
                    isDeath = false
                elseif (harmedPlayer.powerup == PLAYER_SMALL and harmedPlayer.mount == 0) and bouncyLava.getConfig(harmedPlayer.section, "canKill", zones) then -- if player can be killed
                    isDeath = true
                end
            end

            -- have to check forcedstate AFTER other checks or clearpipes break it. i hate bouncyLava sooo much
            if harmedPlayer.forcedState ~= FORCEDSTATE_NONE then
                isDeath = true
            end

            -- If not killed, determine bounce direction
            if  not isDeath  or  not bouncyLava.getConfig(p.section, "canKill", zones) then

                -- magic address, fixed moving blocks just not responding (stood on NPC index)
                harmedPlayer:mem(0x176, FIELD_WORD, 0)

                -- set the slope index to 0 so we can't slide on lava
                harmedPlayer:mem(0x48, FIELD_WORD, 0)

                -- make the player stop sliding encase they are
                harmedPlayer:mem(0x3C, FIELD_BOOL, false)

                -- only do NPCPinched if the culprit has speed, as per source. meant to work with layer crushing, barely works
                if (culpritSpeed.x ~= 0 or culpritSpeed.y ~= 0) then
                    harmedPlayer:mem(0x14E, FIELD_WORD, 2)
                end

                -- Determine the launch direction
                local hpMid = vector(harmedPlayer.x + 0.5*harmedPlayer.width, harmedPlayer.y + 0.5*harmedPlayer.height)
                local cMid = vector(culprit.x + 0.5*culprit.width, culprit.y + 0.5*culprit.height)
                local toCulprit = hpMid-cMid

                local processSpeed = 0
                local appliedSpeed = vector(0,0)
                --local appliedOffset = vector(0,0) -- debug line
                
                local initialPosition = vector(harmedPlayer.x, harmedPlayer.y)

                local zoneSpeed
                zoneSpeed = tonumber(bouncyLava.getConfig(harmedPlayer.section, "strength", zones))  or  16

                if  side ~= SIDE_IN then
                    -- we're not in a block, so figure out directional launching
                    local slopeXModifier = 1

                    if side == SIDE_SLOPE then
                        slopeXModifier =  tonumber(bouncyLava.getConfig(harmedPlayer.section, "slopeStrengthModifier", zones))
                    end

                    local _, hit, normal, _ = Colliders.linecast(hpMid,cMid,culprit,false)

                    processSpeed = zoneSpeed

                    local processTable = {
                        y = {
                            ["-1"] = {coord = hit.y - harmedPlayer.height - 2 + culpritSpeed.y, pinchAddress = 0x146},
                            ["1"] =  {coord = hit.y + 2 + culpritSpeed.y, pinchAddress = 0x14A}
                        },
                        x = {
                            ["-1"] = {coord = hit.x - harmedPlayer.width - 2 + culpritSpeed.x, pinchAddress = 0x14C},
                            ["1"] =  {coord = hit.x + 2 + culpritSpeed.x, pinchAddress = 0x148}
                        }
                    }
                    
                    -- unset NPCPinched if we're dealing with a slope, other wise you'll get killed just walking into one
                    if side == SIDE_SLOPE then
                        harmedPlayer:mem(0x14E, FIELD_WORD, 0)
                    end

                    if normal.x ~= 0 then
                        -- if the block is stationary, adjust coords. should keep the player out of lava
                        if (culpritSpeed.x == 0 and culpritSpeed.y == 0) then
                            harmedPlayer.x = processTable.x[tostring(math.sign(normal.x))].coord
                            checkForBlock(harmedPlayer, culprit, hit)
                        end

                        -- appliedOffset.x = harmedPlayer.x - initialPosition.x -- debug line

                        harmedPlayer:mem(processTable.x[tostring(math.sign(normal.x))].pinchAddress, FIELD_WORD, 2) -- pinch address. meant to work with layer crushing, barely works
                        
                        harmedPlayer.speedX = (processSpeed*slopeXModifier)*normal.x
                        appliedSpeed.x = harmedPlayer.speedX
                    end

                    if normal.y ~= 0 then
                        -- if the block is stationary, adjust coords. should keep the player out of lava
                        if (culpritSpeed.x == 0 and culpritSpeed.y == 0) then
                            harmedPlayer.y = processTable.y[tostring(math.sign(normal.y))].coord
                            checkForBlock(harmedPlayer, culprit, hit)
                        end
                        
                        
                        -- appliedOffset.y = harmedPlayer.y - initialPosition.y -- debug line

                        harmedPlayer:mem(processTable.y[tostring(math.sign(normal.y))].pinchAddress, FIELD_WORD, 2) -- pinch address. meant to work with layer crushing, barely works

                        harmedPlayer.speedY = processSpeed*normal.y
                        appliedSpeed.y = harmedPlayer.speedY
                    end
                else
                    -- we're in a block, so let's get out. (duplicate of checkForBlock, things needed to be this way)
                    local winningSide
                    if math.abs(toCulprit.x) > math.abs(toCulprit.y) then
                        if math.sign(toCulprit.x) == -1 then
                            winningSide = 2
                        else
                            winningSide = 4
                        end
                    else
                        if math.sign(toCulprit.y) == -1 then
                            winningSide = 1
                        else
                            winningSide = 3
                        end
                    end
                    -- set the position so the player ISN'T in the block anymore
                    -- vertical
                    if winningSide == 1 or winningSide == 3 then
                        -- top of block
                        if  winningSide == 1  then
                            harmedPlayer:mem(0x146, FIELD_WORD, 2) -- pinch address. meant to work with layer crushing, barely works
                            harmedPlayer.y = culprit.y - harmedPlayer.height - 2 + culpritSpeed.y
                            appliedSpeed.y = -(zoneSpeed  or  bouncyLava.strength)

                        -- bottom of block
                        else
                            harmedPlayer:mem(0x14A, FIELD_WORD, 2) -- pinch address. meant to work with layer crushing, barely works
                            harmedPlayer.y = culprit.y + culprit.height + 2 + culpritSpeed.y
                            appliedSpeed.y = zoneSpeed  or  bouncyLava.strength
                        end

                        -- appliedOffset.y = harmedPlayer.y - initialPosition.y -- debug line
                        harmedPlayer.speedY = appliedSpeed.y
                    -- horizontal
                    else
                        -- right of block
                        if  winningSide == 2 then
                            harmedPlayer:mem(0x148, FIELD_WORD, 2) -- pinch address. meant to work with layer crushing, barely works
                            harmedPlayer.x = culprit.x - harmedPlayer.width - 2 + culpritSpeed.x
                            appliedSpeed.x = -(zoneSpeed  or  bouncyLava.strength)

                        -- left of block
                        else
                            harmedPlayer:mem(0x14C, FIELD_WORD, 2) -- pinch address. meant to work with layer crushing, barely works
                            harmedPlayer.x = culprit.x + culprit.width + 2 + culpritSpeed.x
                            appliedSpeed.x = zoneSpeed  or  bouncyLava.strength
                        end
                        
                        -- appliedOffset.x = harmedPlayer.x - initialPosition.x -- debug line
                        harmedPlayer.speedX = appliedSpeed.x
                    end
                end

                -- set these for this frame so it carries over to control locks
                data.launchTimer = bouncyLava.launchTime
                harmedPlayer.keys.run = KEYS_UP
                harmedPlayer.keys.altRun = KEYS_UP
                harmedPlayer:mem(0x160, FIELD_WORD, 2)
                harmedPlayer:mem(0x172, FIELD_BOOL, false)

                -- call harm if we should be doing that
                if  (harmedPlayer.powerup ~= PLAYER_SMALL or harmedPlayer.mount > 0) and bouncyLava.getConfig(harmedPlayer.section, "canHarm", zones) then
                    harmedPlayer:harm()
                end

                -- print debug info for some frames
                -- Routine.run(function()
                --     for i=1, 120  do
                --         Text.print("SIDE: "..tostring(side), 20,20)
                --         Text.print("LAVA SPEED: "..tostring(culpritSpeed), 20,40)
                --         Text.print("APPLIED OFFSET: "..tostring(appliedOffset), 20,60)
                --         Text.print("APPLIED SPEED: "..tostring(appliedSpeed), 20,80)
                --         Text.print("LAUNCH TIMER: ".. data.launchTimer, 20,100)
                --         Routine.skip()
                --     end

                --     return true
                -- end)

                -- call bounce event now that we're done
                EventManager.callEvent("onPlayerLavaBounce",harmedPlayer)
            end
        end
    end
end

function bouncyLava.onPlayerKill(eventToken, harmedPlayer)
    -- Check whether lava is responsible
    local adjacentLava = getAdjacentLava(harmedPlayer)
    if  #adjacentLava > 0 then
        eventToken.cancelled = true
        local isDeath = false
        local zones = Colliders.getColliding{a=harmedPlayer, b=bouncyLava.zoneBlockID, btype=Colliders.BLOCK, filter = function(block)
                return (not block.isHidden and not block:mem(0x5A, FIELD_BOOL))
            end}

        -- if onlyZones is true and there are none, let the player die anyways and skip further checks
        if bouncyLava.getConfig(harmedPlayer.section, "onlyZones", zones) and (zones == nil  or  #zones <= 0) then eventToken.cancelled = false return end

        if  (harmedPlayer:mem(0x140,FIELD_WORD) == 0 and bouncyLava.getConfig(harmedPlayer.section, "respectsMercy", zones))  or  (harmedPlayer.forcedState == FORCEDSTATE_NONE  and  harmedPlayer:mem(0x140,FIELD_WORD) < 145  and  not bouncyLava.getConfig(harmedPlayer.section, "respectsMercy", zones)) then
            if (harmedPlayer.powerup ~= PLAYER_SMALL or harmedPlayer.mount > 0) and bouncyLava.getConfig(harmedPlayer.section, "canHarm", zones) then
                isDeath = false
                eventToken.cancelled = true
            elseif (harmedPlayer.powerup == PLAYER_SMALL and harmedPlayer.mount == 0) and bouncyLava.getConfig(harmedPlayer.section, "canKill", zones) then -- if player can be killed
                isDeath = true
                eventToken.cancelled = false
            end
        end
        
        -- don't bother if the settings aren't enabled
        if  not (bouncyLava.enabled or bouncyLava.getConfig(harmedPlayer.section, "enabledOverride")) then
            isDeath = true
            eventToken.cancelled = false
        end

        -- If killed, call a different event
        if  isDeath  then
            EventManager.callEvent("onPlayerLavaDeath", harmedPlayer)
        end  
    end    
end

return bouncyLava;
