local npcManager = require("npcManager")
local ai = require("AI/popperupper_ai")
local popper = {}

local npcID = NPC_ID

npcManager.registerHarmTypes(npcID, 
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA
	}, {
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 28,
	width = 32,
	height = 28,
	frames = 1,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 1,
	nohurt=true,
	jumphurt = true,
	noblockcollision = true,
	ignorethrownnpcs = true,
	nofireball=true,
	noiceball=true,
	noyoshi=true,
	nogliding=true, -- The NPC ignores gliding blocks (1f0)
	stoponcontact=false,
	stoponsolids=false,
	stoponnpcs=false
})


function popper.onInitAPI()
	ai.registerProjectile(npcID)
end

return popper