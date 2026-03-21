--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("dustBunny_ai")


local dustBunny = {}
local npcID = NPC_ID

local dustBunnySettings = table.join({
	id = npcID,
	
	
},ai.sharedSettings)

npcManager.setNpcSettings(dustBunnySettings)
npcManager.registerHarmTypes(npcID,{},{})


function dustBunny.getPosition(v,data,config,settings,time)
	local angle = time/settings.cycleDuration*360*v.direction + settings.startingRotation
	local angleRad = math.rad(angle)

	local x = math.sin(angleRad) * settings.horizontalDistance * 0.5
	local y = -math.cos(angleRad) * settings.verticalDistance * 0.5

	--[[local eyeRotation = angle - 90

	if settings.horizontalDistance < 0 then
		eyeRotation = -eyeRotation
	end
	if settings.verticalDistance < 0 then
		eyeRotation = -eyeRotation + 180
	end
	if v.direction == DIR_RIGHT then
		eyeRotation = eyeRotation + 180
	end]]

	return x,y
end

function dustBunny.getBoundingBox(v,data,config,settings)
	local width = (settings.horizontalDistance + v.spawnWidth)*0.5
	local height = (settings.verticalDistance + v.spawnHeight)*0.5

	return -width,-height,width,height
end


ai.register(npcID,dustBunny.getPosition,dustBunny.getBoundingBox)


return dustBunny