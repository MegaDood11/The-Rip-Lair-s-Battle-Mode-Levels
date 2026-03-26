local blockManager = require("blockManager")

local sampleBlock = {}

local blockID = BLOCK_ID

local sampleBlockSettings = {
	id = blockID
}

blockManager.setBlockSettings(sampleBlockSettings)

function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onTickEndBlock")
end

function sampleBlock.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	
	for _,p in ipairs(Player.get()) do
		if v:collidesWith(p) > 0 then
			p:harm()
		end
	end
end

--Gotta return the library table!
return sampleBlock