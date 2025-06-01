local sampleNPC = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

local talk = Graphics.loadImageResolved("hardcoded-43.png")

function sampleNPC.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	data.canTalk = false
	data.timer = data.timer or 0
	data.timer = data.timer - 1
	
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(p, v) then
			data.canTalk = true
			if p.keys.up == KEYS_PRESSED and data.timer <= 0 then
				if not data.friend or data.friend ~= 35 then SFX.play("yee haw.wav") else SFX.play("you're in danger boy.wav") end
				data.timer = 160
				data.friend = RNG.randomInt(1,35)
			end
		end
	end
end

function sampleNPC.onDrawNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if data.canTalk then
		data.talk = data.talk or Sprite{texture = talk, frames = 1}
		data.talk.position = vector(v.x + v.width * 0.375, v.y - v.height * 0.25)
		data.talk:draw{sceneCoords = true, frame = 1, priority = -47}
	end
end


function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

return sampleNPC