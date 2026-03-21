--[[
	cloudlifts.lua v1.1 by "Master" of Disaster
	
	Very similar to launchpad.lua. The Cloud lift thingies from Mario Wonder
--]]


local cloudlifts = {
	blockedNPCs = {		-- the ids of all npcs that should not squish the platform
		10, 11, 33, 46, 60, 62, 64, 66, 88, 91, 97, 103, 105, 106, 151, 152, 160, 192, 196, 197, 203, 204, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220,
		221, 222, 223, 224, 225, 226, 227, 251, 252, 253, 260, 289, 310, 378, 397, 398, 399, 400, 418, 423, 424, 430, 465, 528, 570, 582, 583, 591, 592, 593,
		594, 595, 596, 597, 598, 599, 600, 601, 602, 603,
	},
	defaultHideTime = 200,	-- how long it hides by default. Can be overwritten by npc configs
	defaultBrittleness = 0.02,	-- how fast the lift lowers when pressured
	defaultRiseSpeed = 0.03,	-- how fast the lift recovers
	defaultGPmodifier = 8,		-- multiplied with brittleness when ground pounding
	
}

local cloudliftsIDs = {}

local particles = require("particles")

local folderpath = "AI/cloud lifts/"


local npcManager = require("npcManager")
local easing = require("ext/easing")

local GP
pcall(function() GP = require("GroundPound") end)
GP = GP or {isPounding = function() return false, 0 end}


-- by MDA
local function drawSegmentedBox(image,priority,sceneCoords,color,x,y,width,height,cutoffWidth,cutoffHeight,target)
    local vertexCoords = {}
    local textureCoords = {}

    local vertexCount = 0

    local segmentWidth = image.width / 3
    local segmentHeight = image.height / 3

    local segmentCountX = math.max(2,math.ceil(width / segmentWidth))
    local segmentCountY = math.max(2,math.ceil(height / segmentHeight))

    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)

    for segmentIndexX = 1, segmentCountX do
        for segmentIndexY = 1, segmentCountY do
            local thisX = x
            local thisY = y
            local thisWidth = math.min(width * 0.5,segmentWidth)
            local thisHeight = math.min(height * 0.5,segmentHeight)
            local thisSourceX = 0
            local thisSourceY = 0

            if segmentIndexX == segmentCountX then
                thisX = thisX + width - thisWidth
                thisSourceX = image.width - thisWidth
            elseif segmentIndexX > 1 then
                thisX = thisX + thisWidth + (segmentIndexX-2)*segmentWidth
                thisWidth = math.min(segmentWidth,width - segmentWidth - (thisX - x))
                thisSourceX = segmentWidth
            end

            if segmentIndexY == segmentCountY then
                thisY = thisY + height - thisHeight
                thisSourceY = image.height - thisHeight
            elseif segmentIndexY > 1 then
                thisY = thisY + thisHeight + (segmentIndexY-2)*segmentHeight
                thisHeight = math.min(segmentHeight,height - segmentHeight - (thisY - y))
                thisSourceY = segmentHeight
            end
            

            -- Handle cutoff
            if cutoffWidth ~= nil and cutoffHeight ~= nil then
                local cutoffLeft = x + width*0.5 - cutoffWidth*0.5
                local cutoffRight = cutoffLeft + cutoffWidth
                local cutoffTop = y + height*0.5 - cutoffHeight*0.5
                local cutoffBottom = cutoffTop + cutoffHeight

                -- Handle X
                local offset = math.max(0,cutoffLeft - thisX)

                thisWidth = thisWidth - offset
                thisSourceX = thisSourceX + offset
                thisX = thisX + offset

                thisWidth = math.min(thisWidth,cutoffRight - thisX)

                -- Handle Y
                local offset = math.max(0,cutoffTop - thisY)

                thisHeight = thisHeight - offset
                thisSourceY = thisSourceY + offset
                thisY = thisY + offset

                thisHeight = math.min(thisHeight,cutoffBottom - thisY)
            end

            -- Add vertices
            if thisWidth > 0 and thisHeight > 0 then
                local x1 = thisX
                local y1 = thisY
                local x2 = x1 + thisWidth
                local y2 = y1 + thisHeight

                vertexCoords[vertexCount+1 ] = x1 -- top left
                vertexCoords[vertexCount+2 ] = y1
                vertexCoords[vertexCount+3 ] = x1 -- bottom left
                vertexCoords[vertexCount+4 ] = y2
                vertexCoords[vertexCount+5 ] = x2 -- top right
                vertexCoords[vertexCount+6 ] = y1
                vertexCoords[vertexCount+7 ] = x1 -- bottom left
                vertexCoords[vertexCount+8 ] = y2
                vertexCoords[vertexCount+9 ] = x2 -- top right
                vertexCoords[vertexCount+10] = y1
                vertexCoords[vertexCount+11] = x2 -- bottom right
                vertexCoords[vertexCount+12] = y2

                local x1 = thisSourceX / image.width
                local y1 = thisSourceY / image.height
                local x2 = (thisSourceX + thisWidth) / image.width
                local y2 = (thisSourceY + thisHeight) / image.height

                textureCoords[vertexCount+1 ] = x1 -- top left
                textureCoords[vertexCount+2 ] = y1
                textureCoords[vertexCount+3 ] = x1 -- bottom left
                textureCoords[vertexCount+4 ] = y2
                textureCoords[vertexCount+5 ] = x2 -- top right
                textureCoords[vertexCount+6 ] = y1
                textureCoords[vertexCount+7 ] = x1 -- bottom left
                textureCoords[vertexCount+8 ] = y2
                textureCoords[vertexCount+9 ] = x2 -- top right
                textureCoords[vertexCount+10] = y1
                textureCoords[vertexCount+11] = x2 -- bottom right
                textureCoords[vertexCount+12] = y2

                vertexCount = vertexCount + 12
            end
        end
    end

    Graphics.glDraw{
        texture = image,
        priority = priority,
        color = color,
        sceneCoords = sceneCoords,
        vertexCoords = vertexCoords,
        textureCoords = textureCoords,
		target = target,
    }
end

local function blockFilter(o)
    if not o.isHidden and (Block.SOLID_MAP[o.id]) then
        return true	-- check whether it's a solid block, or hidden
    end
end

local function semiSolidBlockFilter(o)
	if (Block.SEMISOLID_MAP[o.id] or Block.SOLID_MAP[o.id]) and not o.isHidden then
		return true
	end
end

local function npcFilter(o) -- filters out all the npcs that should not be squishig the platform
	if not NPC.config[o.id].nogravity and not NPC.config[o.id].noblockcollision and o.isValid and not o.isHidden
			and not table.contains(cloudlifts.blockedNPCs,o.id) and not o.heldPlayer then
		return true
	end
end


function cloudlifts.register(id)
	npcManager.registerEvent(id, cloudlifts, "onTickNPC")
	--npcManager.registerEvent(id, cloudlifts, "onTickEndNPC")
	npcManager.registerEvent(id, cloudlifts, "onDrawNPC")
	--registerEvent(cloudlifts, "onNPCHarm")
	cloudliftsIDs[id] = true
end


function cloudlifts.onTickNPC(v)

	if not v.isValid or v.despawnTimer < 0 or (v.isHidden and not v.data.isHiding) then
		v.data.activated = false
		return 
	end
	
	local data = v.data
	local settings = data._settings
	
	if not data.activated then		-- initializes all the data
		data.squish = 1
		data.respawnSquish = 1	-- just visual, only below 1 if it's just respawning
		
		v.width = settings.width

		v.height = settings.height - 2
		
		data.startHeight = settings.height - 2
		data.prevHeight = v.height
		
		local dY = data.startHeight - 32
		data.segmentCount = math.floor(dY/32)
		if settings.spawnheight > 32 then
			data.squish = (settings.spawnheight-32)/(data.startHeight-32)
		end
		
		v.y = v.y - (v.height-32)
		v.x = v.x - (v.width-32) * 0.5
		
		data.isPressured = 0		-- if > 0, the cloud lift will retract
		data.playerPressured = 0	-- used to find out when the player lands on it
		data.blockPressured = 0		-- if a block is in it's way, don't rise
		
		data.lookPained = 0	-- counts up when it's pressured. If it has been pressured by at least 5 frames, it'll look pained
		
		data.unsquishTimer = 0
		
		data.maxSquish = 1
		
		data.isHiding = false	-- whether the cloud lift is currently intangible
		data.wasHiding = false	-- true when isHiding is true, gets set to false one frame later
		data.hideTimer = 0		-- counts up if intangible. Can only respawn if it's spawn isn't blocked and if this timer reached a certain value
		
		data.brittleness = NPC.config[v.id].brittleness or cloudlifts.defaultBrittleness	-- get all the data from the npc config, and if that doesn't exist, from the default library values
		data.hideDuration = NPC.config[v.id].hideDuration or cloudlifts.defaultHideTime
		data.riseSpeed = NPC.config[v.id].riseSpeed or cloudlifts.defaultRiseSpeed
		data.gpModifier = NPC.config[v.id].gpModifier or cloudlifts.defaultGPmodifier
		
		data.collider = Colliders.Rect(0,0,1,1,0)	-- collider that checks whether it is pressured, blocked by a block and can respawn
		data.collider.width = v.width
		data.collider.height = 4
		
		if settings.spawnheight == -1 then	-- shall spawn fully squished
			data.isHiding = true
			data.wasHiding = true
			v.isHidden = true
			data.squish = 0
			data.hideTimer = data.hideDuration - 20
		end
		
		
		data.puffyParticle = particles.Emitter(0,0,Misc.resolveFile(folderpath .. "particles_puffclouds-".. tostring(v.id) .. ".ini"))	-- the cloud puff particle
		data.puffyParticle:setParam("xOffset",-v.width *0.5 ..":"..v.width * 0.5)
		data.puffyParticle:setParam("yOffset",-v.height*0.5- 16 .. ":" .. -v.height*0.5+ 16)
		data.puffyParticle:attach(v)
		
		
		data.activated = true		-- all right, all the data is initialized!
	end
	if data.isHiding and not v.isHidden then	-- when it's shown via layers and events, hide it again. It breaks otherwise!
		v.isHidden = true
	end
	
	if (v.width ~= settings.width and v.width ~= 127.9 and v.width ~= 255.9) and not data.isHiding then		-- a failsave, in case the npc got unloaded or something. Resets their width and height to the proper values
		-- You think someone would do that? Just go into the code and arbitrarily offset the width of very specific width npcs?
		v.width = settings.width
		v.height = (settings.height - 2)
		v.y = v.y - (v.height-32)
		v.x = v.x - (v.width-32) * 0.5
		if settings.spawnheight > 32 and not data.wasHiding then
			data.squish = (settings.spawnheight-32)/(data.startHeight-32)
		elseif settings.spawnheight == -1 and not data.wasHiding then
			data.squish = 0
		end
		data.wasHiding = false
	end
	
	data.collider.x = v.x + v.width * 0.5
	data.collider.y = v.y
	
	-- whether an npc steps on it
	for k, n in ipairs(Colliders.getColliding{a = data.collider, btype = Colliders.NPC, filter = npcFilter}) do
		if not v.isHidden then
			local prevSquish = data.squish
			local weight = n:getWeight() + 1
			local liftHeight = (settings.height - 32) / 32
			if n.speedY > 3 then
				data.squish = math.max(0, data.squish - (weight * data.brittleness * 0.5 * n.speedY)/ liftHeight)
			end
			data.squish = math.max(0,data.squish - (weight * data.brittleness)/liftHeight)
		
			data.isPressured = 3
			
			local collidesWithBlock = false
			for k,b in ipairs(Block.getIntersecting(n.x,n.y + n.height, n.x + n.width, n.y + n.height + (prevSquish - data.squish) * (data.startHeight - 48))) do
				if semiSolidBlockFilter(b) then
					collidesWithBlock = true
				end
			end
			if not collidesWithBlock then
				n.y = n.y + (prevSquish - data.squish) * (data.startHeight - 48)
			end
		end
	end
	
	-- whether the player steps on it
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(p,data.collider) then
			if not v.isHidden then
				local weight = p:getWeight()
				local liftHeight = (settings.height - 32) / 32
				if data.playerPressured == 0 then	-- if the player just lands on the thing, make it retract more!
					if p.speedY > 3 then
						local prevSquish = data.squish
						local modifier = data.brittleness
						if GP.isPounding(p) then	-- extra velocity when ground pounding
							modifier = data.brittleness * data.gpModifier
						end
						data.strongSquishTo = math.max(0,data.squish - (weight * modifier * p.speedY) / liftHeight)	-- since this squishes it quite a lot, do it with easing!
					end
				end
				data.squish = math.max(0,data.squish - (weight * data.brittleness * 0.5)/ liftHeight)	-- retract the platform
				data.playerPressured = 3
			end
			data.isPressured = 3
		end
	end
	
	-- whether it's hitting a block. If so, it should stop rising.
	data.collider.width = settings.width  - 2
	for k, n in ipairs(Colliders.getColliding{a = data.collider, btype = Colliders.BLOCK, filter = blockFilter}) do
		data.blockPressured = 3
	end
	data.collider.width = settings.width
		
	if not data.isHiding then
		data.collider.height = 4
		
		if data.strongSquishTo then
			local randomValue = math.random()
			--Misc.dialog(data.squish-data.strongSquishTo)
			if randomValue <= (v.width / 160) then
				data.puffyParticle:Emit(math.max(1,math.floor(v.width/160 * (data.squish-data.strongSquishTo)+0.5)))
			end
			if not data.strongSquishTimer then
				data.strongSquishTimer = 0
			end
				local prevSquish = data.squish
				
				local easingTimer = data.strongSquishTimer
				local easedValue = easing.outQuad(easingTimer,0,1,20,0.8,0.4)
				data.squish = math.min(data.squish,math.lerp(data.squish,data.strongSquishTo,easedValue))
			
				for _,p in ipairs(Player.get()) do
					if Colliders.collide(p,data.collider) then
						local collidesWithBlock = false
						for k,b in ipairs(Block.getIntersecting(p.x,p.y + p.height, p.x + p.width, p.y + p.height + (prevSquish - data.squish) * (data.startHeight - 48))) do
							if semiSolidBlockFilter(b) then
								collidesWithBlock = true
							end
						end
						if not collidesWithBlock then
							p.y = p.y + (prevSquish - data.squish) * (data.startHeight - 48)
						end
					end
				end
				
				data.strongSquishTimer = data.strongSquishTimer + 1
			
			if data.squish <= data.strongSquishTo then
				data.strongSquishTimer = nil
				data.strongSquishTo = nil
			end
		else
			data.strongSquishTimer = nil
		end
		
		if data.squish <= 0 then	-- so squished it literally disappears!
			--v.isHidden = true
			--Misc.dialog(data.squish,data.respawnSquish,data.hideTimer,data.strongSquishTo,data.isPressured)
			data.isHiding = true
			data.wasHiding = true
			v.isHidden = true
		end
		
		if data.isPressured > 0 then		-- counts the values down. If isPressured is 0, the launchpad will unsquish
			data.puffyParticle:setParam("yOffset",-v.height*0.5 - 16 .. ":" .. -v.height*0.5+ 16)
			data.puffyParticle:setParam("col",Color(1,0.5 + 0.5 * data.squish,0.5 + 0.5 * data.squish))
			local randomValue = math.random()
			if randomValue <= v.width / 640 then
				data.puffyParticle:Emit(1)
			end
			data.isPressured = data.isPressured - 1
			data.playerPressured = math.max(0,data.playerPressured - 1)
			data.maxSquish = data.squish
			data.lookPained = data.lookPained + 1
		else		
			data.lookPained = 0
			-- unsquishing
			local liftHeight = (settings.height - 32) / 32
			if not data.isHiding and data.blockPressured == 0 then
				data.squish = math.min(1,data.squish + data.riseSpeed / liftHeight)
			end
		end
		
		if data.blockPressured > 0 then
			data.blockPressured = data.blockPressured - 1
		end
		
	elseif v.isHidden and data.isHiding then	-- plays when it is squished enough that it's hidden
		data.puffyParticle:setParam("yOffset",-v.height*0.5 .. ":" .. -v.height*0.5+ 32)
		data.puffyParticle:setParam("col",Color(1,0.5 + 0.5 * data.squish,0.5 + 0.5 * data.squish))
		local randomValue = math.random()
		if randomValue <= v.width / 160 then
			data.puffyParticle:Emit(math.max(1,math.floor(v.width/160+0.5)))
		end
		data.collider.height = 32	-- this collider now checks whether something is interfering with it's respawn position
		v.y = v.y + (data.startHeight - 32)
		data.collider.y = v.y
		
		if data.hideTimer >= data.hideDuration then
			if data.isPressured == 0 and data.blockPressured == 0 then	-- respawn when it did the time and nothing is obstructing it's spawn
				data.hideTimer = 0
				v.isHidden = false
				data.isHiding = false
				data.respawnSquish = 0
				data.squish = 0.00001		-- odd bandaid solution to fix the squished animation
			else
				data.hideTimer = data.hideDuration - 10
			end
		end
		if math.abs(v.x + v.width * 0.5 - camera.x - camera.width * 0.5) < camera.width * 0.5 + 96 then
			data.hideTimer = data.hideTimer + 1
		end
		if data.isPressured > 0 then
			data.isPressured = data.isPressured - 1
		end
		if data.blockPressured > 0 then
			data.blockPressured = data.blockPressured - 1
		end
	end
	
	
	if not data.isHiding and data.respawnSquish < 1 then
		data.respawnSquish = math.min(1,data.respawnSquish + 0.1)
	elseif data.isHiding and data.respawnSquish > 0 then
		data.respawnSquish = data.respawnSquish - 0.2
	end
	v.height = 32 + data.squish * (data.startHeight - 32)
	v.y = v.y - (v.height - data.prevHeight)
	
	data.prevHeight = v.height

end

function cloudlifts.onDrawNPC(v)
	
	if (v.isHidden and not v.data.isHiding) or not v.isValid or not v.data.activated or v.despawnTimer < 0 then return end
	local data = v.data
	local bottomSprites = Graphics.loadImageResolved(folderpath .. "npc-".. tostring(v.id) .. "bottom.png")  
	local middleSprites = Graphics.loadImageResolved(folderpath .. "npc-".. tostring(v.id) .. "middle.png")  
	local topSprites = Graphics.loadImageResolved(folderpath .. "npc-".. tostring(v.id) .. "top.png")

	local squishColor = Color(1,0.5 + 0.5 * data.squish,0.5 + 0.5 * data.squish)
	
	if not data.middleBuffer then		-- huge thanks to Marioman for more efficient drawing code! There'd be so many draw calls otherwise
		local img = middleSprites
		data.middleBuffer = Graphics.CaptureBuffer(data._settings.width * 0.5, data.startHeight * 0.5,true)
		drawSegmentedBox(
			--[[image=]]img,
			--[[priority=]]-100,
			--[[sceneCoords=]]false,
			--[[color=]] Color.white .. 1,
			--[[x=]]0,
			--[[y=]](0)*img.height,
			--[[width =]] data._settings.width * 0.5,
			--[[height =]] data.startHeight * 0.5,
			--[[cutoffWidth =]] nil,
			--[[cutoffHeight =]] nil,
			--[[target =]]data.middleBuffer
		)
		
		data.bottomBuffer = Graphics.CaptureBuffer(data._settings.width * 0.5,16,true)
		local img = bottomSprites
		drawSegmentedBox(
			--[[image=]]img,
			--[[priority=]]-100,
			--[[sceneCoords=]]false,
			--[[color=]] Color.white .. 1,
			--[[x=]]0,
			--[[y=]]0,
			--[[width =]] data._settings.width * 0.5,
			--[[height =]] 16,
			--[[cutoffWidth =]] nil,
			--[[cutoffHeight =]] nil,
			--[[target =]] data.bottomBuffer
		)
		
		data.topBuffer = Graphics.CaptureBuffer(data._settings.width * 0.5,16,true)
		local img = topSprites
		drawSegmentedBox(
			--[[image=]]img,
			--[[priority=]]-100,
			--[[sceneCoords=]]false,
			--[[color=]] Color.white .. 1,
			--[[x=]]0,
			--[[y=]]0,
			--[[width =]] data._settings.width * 0.5,
			--[[height =]] 16,
			--[[cutoffWidth =]] nil,
			--[[cutoffHeight =]] nil,
			--[[target =]] data.topBuffer
		)
	end

	if data.respawnSquish > 0 and not data.hideNextFrame then
		local width = data._settings.width
		-- draw the middle segment
		local img = data.middleBuffer
		local height = math.max(0,v.height - 32) -- current height and not the total height

		Graphics.drawBox{
			texture = img,
			x = v.x + v.width/2,
			y = v.y + v.height * 0.5,-- + height/2,
			width = width,
			height = height * data.respawnSquish,
			sourceWidth = img.width,
			sourceHeight = img.height,--height * 0.5,
			sourceX = 0,
			sourceY = 0,--(data.startHeight -v.height) * 0.5,
			sceneCoords = true,
			centered = true,
			priority = -47,
			color =  squishColor .. 1,
		}

		
		-- draw the bottom part
		local img = data.bottomBuffer
		
		Graphics.drawBox{
			texture = img,
			x = v.x + v.width/2,
			y = v.y + v.height - img.height,-- + height/2,
			width = width,
			height = 32 * data.respawnSquish,
			sourceWidth = img.width,
			sourceHeight = img.height,
			sourceX = 0,
			sourceY = 0,
			sceneCoords = true,
			centered = true,
			priority = -46,
			color =  squishColor .. 1,
		}
		
		-- draw the top part
		local img = data.topBuffer
		Graphics.drawBox{
			texture = img,
			x = v.x + v.width/2,
			y = v.y + img.height,-- + height/2,
			width = width,
			height = (32) * data.respawnSquish,
			sourceWidth = img.width,
			sourceHeight = img.height,
			sourceX = 0,
			sourceY = 0,
			sceneCoords = true,
			centered = true,
			priority = -45,
			color =  squishColor .. 1,
		}
		
		local img = Graphics.loadImageResolved(folderpath .. "npc-" .. tostring(v.id) .. "eyes.png")
		local expression = 0
		if data.lookPained > 4 then
			expression = 1
		end
		Graphics.drawBox{
			texture = img,
			x = v.x + v.width/2,
			y = v.y + 14,-- + height/2,
			width = 32,
			height = (16) * data.respawnSquish,
			sourceWidth = img.width,
			sourceHeight = img.height * 0.5,
			sourceX = 0,
			sourceY = expression * img.height * 0.5,
			sceneCoords = true,
			centered = true,
			priority = -44,
		}
	end
	
	data.puffyParticle:draw(-30)
end

return cloudlifts