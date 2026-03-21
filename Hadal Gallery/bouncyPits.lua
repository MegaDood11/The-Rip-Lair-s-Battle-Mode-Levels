------------------------------------------------------
--[[ bouncyPits.lua v1.4.0 by rixitic & KBM-Quine ]]--
------------------------------------------------------

local bouncyPits = {
	-- library only vars
	enabled = true, -- basic flip switch for functionality
	zoneBlockID = 755, -- block id considered for zone checks
	sectionConfig = {}, -- stores per-section settings

	-- setting shared with per-section configs
	enabledOverride = false, -- overrides enabled. useful for making specifc sections force bouncyPits
	onlyZones = false, -- makes pit processing only run for bouncy zones
	bottom = nil, -- configureable bottom boundary that is considered a pit. falls back to the bottom of players' section

	-- settings shared with per-zone & per-section configs
	strength = 13.5, -- strength of a bounce after falling in a pit 
	respectsMercy = true, -- whether or not harming or killing is done during invulnerability frames
	canHarm = true, -- whether or not harm is call on bounce
	canKill = true, -- whether or not the player is killed when small
}

-- Helper function; dummies out table for section settings to avoid nil entry access
local function initSection(id)
	bouncyPits.sectionConfig[id] = bouncyPits.sectionConfig[id]  or  {}
end

-- set up settings for section specified
-- sets the config specified in props to the value given
-- if props is otherwise a table, fills the section config with that table
function bouncyPits.configureSection(sectionID, props, value)
	if (sectionID == nil or type(sectionID) ~= "number" or sectionID ~= math.floor(sectionID) or (sectionID < 0 or sectionID > 20)) then error('nil, non-number, or invalid section "' .. sectionID .. '" supplied', 1) end
	initSection(sectionID)
	local tbl = bouncyPits.sectionConfig[sectionID]

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
function bouncyPits.getConfig(sectionID, setting, zones)
	if  sectionID == nil  or  sectionID == -1  then
		sectionID = player.section
	end

	initSection(sectionID)
	if (zones ~= nil  and  #zones > 0 and zones[1].data._settings[setting] ~= nil) then
		return zones[1].data._settings[setting]
	elseif (setting ~= nil and bouncyPits.sectionConfig[sectionID][setting] ~= nil) then
		return bouncyPits.sectionConfig[sectionID][setting]
	elseif (setting ~= nil and bouncyPits[setting] ~= nil) then
		return bouncyPits[setting]
	elseif setting == nil then
		return bouncyPits.sectionConfig[sectionID]
	end
end

-- main logic; determines what a pit is and how the player should react
local function processPit(p)
	local isFallDeath = false
	local zones = Colliders.getColliding{a=p, b=bouncyPits.zoneBlockID, btype=Colliders.BLOCK, filter = function(block)
		return (not block.isHidden and not block:mem(0x5A, FIELD_BOOL))
	end}

	if bouncyPits.getConfig(p.section, "onlyZones", zones) and (zones == nil  or  #zones <= 0) then isFallDeath = true end -- if only zones should apply and there aren't any, skip further checks

	if (not isFallDeath and p:mem(0x140,FIELD_WORD) == 0  and  bouncyPits.getConfig(p.section, "respectsMercy", zones)) -- if we're dieing, checks if mercy needs to be respected... 
	    or  (not isFallDeath and p.forcedState == FORCEDSTATE_NONE  and  not bouncyPits.getConfig(p.section, "respectsMercy", zones)) -- or ignored
	then
		if (p.powerup ~= PLAYER_SMALL or p.mount > 0) and bouncyPits.getConfig(p.section, "canHarm", zones) then -- if player can be harmed
			p:harm()
		elseif (p.powerup == PLAYER_SMALL and p.mount == 0) and bouncyPits.getConfig(p.section, "canKill", zones) then -- if player can be killed
			isFallDeath = true
		end
	end
	
	if  not isFallDeath  or  not bouncyPits.getConfig(p.section, "canKill", zones) then -- if we can't be killed currently, bounce
		local bottom = (bouncyPits.getConfig(p.section, "bottom")  or  p.sectionObj.boundary.bottom + 64)
		p.y = bottom - p.speedY -- move player out of kill plane relative to momentum. fix for respectsMercy being false leading to players dieing instead of bouncing
		p.speedY = -(tonumber(bouncyPits.getConfig(p.section, "strength", zones)) or 16)
	end

	return isFallDeath, zones
end

function bouncyPits.onInitAPI()
	registerEvent(bouncyPits, "onTick")
	registerEvent(bouncyPits, "onPlayerKill")
end

function bouncyPits.onPlayerKill(eventToken, harmedPlayer)
	local sId = harmedPlayer.section
	local bottom = bouncyPits.getConfig(sId, "bottom")
	

	local applyBouncing = bouncyPits.enabled or bouncyPits.getConfig(sId, "enabledOverride") -- if bouncing should apply as-per the settings of the library or section 
	local inPit = harmedPlayer.y > (bottom  or  harmedPlayer.sectionObj.boundary.bottom + 64) -- whether the player is in a pit
	
	if  inPit  then
		if  applyBouncing  then
			local isDeath, zones = processPit(harmedPlayer)

			if isDeath and bouncyPits.getConfig(sId, "canKill", zones) then -- if the pit says we died, call onPlayerPitDeath. useful for customizing pit deaths
				EventManager.callEvent("onPlayerPitDeath", harmedPlayer)
			else
				eventToken.cancelled = true
				EventManager.callEvent("onPlayerPitBounce", harmedPlayer) -- if the pit says we bounced, call onPlayerPitBounce. useful for customizing pit bouncing
			end
		else
			EventManager.callEvent("onPlayerPitDeath", harmedPlayer) -- if the pit says we died, call onPlayerPitDeath. useful for customizing pit deaths
		end
	end
end

function bouncyPits.onTick()
	-- if loaded on the overworld, don't bother
	if  isOverworld  then
		return
	end

	-- if the "bottom" config is filled out, manually kill players if their lower then it and not already dead.
	for  _,p in ipairs(Player.get())  do
		local bottom = bouncyPits.getConfig(p.section, "bottom")
		if  bottom ~= nil  and  p.y > bottom and  p.deathTimer == 0 and p.forcedState == FORCEDSTATE_NONE then
			p:kill()
		end
	end
end

return bouncyPits;