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
	return 0,0
end

function dustBunny.update(v,data,config,settings)
	if data.eyeType <= 0 then
		return
	end

	local stareAtSettings = settings.stareAt

	if data.storedEyeRotation == nil then
		data.storedEyeRotation = settings.eyeRotation
	end

	if stareAtSettings.enabled then
		local p = npcutils.getNearestPlayer(v)
		local distance = vector((p.x + p.width*0.5) - (v.x + v.width*0.5),(p.y + p.height*0.5) - (v.y + v.height*0.5))

		local defaultRotation = settings.eyeRotation
		local targetRotation = defaultRotation

		if stareAtSettings.maxPlayerDistance <= 0 or distance.length <= stareAtSettings.maxPlayerDistance then
			-- Find the rotation to stare at the player
			targetRotation = math.deg(math.atan2(distance.y,distance.x)) + 90
		end

		data.storedEyeRotation = math.anglelerp(data.storedEyeRotation,targetRotation,0.0625)
	end

	data.eyeRotation = data.storedEyeRotation
end

function dustBunny.getRandomEye(v,data,config,settings)
	if RNG.randomInt(1,3) == 1 then
		return RNG.randomInt(1,ai.eyeTypeCount)
	else
		return 0
	end
end


ai.register(npcID,dustBunny.getPosition,nil,dustBunny.update,dustBunny.getRandomEye)


return dustBunny