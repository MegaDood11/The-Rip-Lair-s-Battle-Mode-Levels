--------------------------------------------------
-- Level code
-- Created 18:19 2025-7-28
--------------------------------------------------

-- Run code on level start
function onStart()
    --Your code here
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
    for k,v in ipairs(Block.get(2)) do
		v:setSize(48,48)
	end
	for k,v in ipairs(Block.get(65)) do
		v:setSize(48,48)
	end
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

