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


local function getPositionValue(time,waitTime,moveTime)
	local t = time

	if t < moveTime then
		return t/moveTime,1
	else
		t = t - moveTime
	end

	if t < waitTime then
		return 1,math.lerp(1,-1,t/waitTime)
	else
		t = t - waitTime
	end

	if t < moveTime then
		return 1 - t/moveTime,-1
	else
		t = t - moveTime
	end

	return 0,math.lerp(-1,1,t/waitTime)
end


function dustBunny.getPosition(v,data,config,settings,time)
	local waitTime = settings.waitTime/200*settings.cycleDuration
	local moveTime = (settings.cycleDuration - waitTime*2) * 0.5

	local positionValue,eyeDistance = getPositionValue(time % settings.cycleDuration,waitTime,moveTime)
	local eyeRotation = math.deg(math.atan2(settings.verticalDistance,settings.horizontalDistance)) + 90


	local x = settings.horizontalDistance*(positionValue - 0.5)
	local y = settings.verticalDistance  *(positionValue - 0.5)

	return x,y,eyeRotation,eyeDistance
end

--[[function dustBunny.getBoundingBox(v,data,config,settings)
	
end]]


ai.register(npcID,dustBunny.getPosition,dustBunny.getBoundingBox)


return dustBunny