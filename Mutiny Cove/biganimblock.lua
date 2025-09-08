-- AI file for >32x32 non-sizable animated blocks. Yes, we needed this. Apparently.
--script by AutumnMood

local bigblock = {}

local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

function bigblock.register(id)
	blockmanager.registerEvent(id, bigblock, "onCameraDrawBlock")
end

function bigblock.onCameraDrawBlock(v, cam)
    local cam = Camera(cam)
	local data = v.data._basegame
	
	-- Blocks "animate" even when invisible or offscreen.
	if not data.biganimTimer then
		local config = Block.config[v.id]
		data.biganimTimerMax = config.framespeed
		data.biganimTimer = -1
		data.biganimFrameMax = config.frames
		data.biganimFrame = 0
	end
	
	--we take the block frame index, and yeet it into the stratosphere
	blockutils.setBlockFrame(v.id, -1000)
	
	data.biganimTimer = data.biganimTimer + 1
	if data.biganimTimer == data.biganimTimerMax then
		data.biganimFrame = data.biganimFrame + 1
		if data.biganimFrame == data.biganimFrameMax then
			data.biganimFrame = 0
		end
		data.biganimTimer = 0
	end
	
    if not blockutils.visible(cam, v.x, v.y, v.width, v.height) then return end
    if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	Graphics.drawImageToSceneWP(
		Graphics.sprites.block[v.id].img,
		v.x,
		v.y + v:mem(0x56,FIELD_WORD),
		0,
		v.height * data.biganimFrame,
		v.width,
		v.height,
		-65
	)
end

return bigblock

