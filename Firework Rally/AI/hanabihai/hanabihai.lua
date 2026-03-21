--[[
	Hanabihai v1.1 by "Master" of Disaster
	
]]
local folderPath = "AI/hanabihai/"
local basesprites = Graphics.loadImageResolved(folderPath.."hanabihaiBottom.png")			-- spritesheet for the base segment (while walking)
local hurtsprites = Graphics.loadImageResolved(folderPath.."hanabihaiHurt.png")			-- spritesheet for the base segment (while hurt)
local segmentsprites = Graphics.loadImageResolved(folderPath.."hanabihaiSegments.png")	-- spritesheet for the different segments, including the top

local baseoverlaysprites = Graphics.loadImageResolved(folderPath.."hanabihaiBottomOverlay.png") -- overlay sprites for the base
local hurtoverlaysprites = Graphics.loadImageResolved(folderPath.."hanabihaiHurtOverlay.png")			-- spritesheet for the base segment (while hurt)
local segmentoverlaysprites = Graphics.loadImageResolved(folderPath.."hanabihaiSegmentsOverlay.png")	-- spritesheet for the different segments, including the top

local particles = require("particles")
local fireworkParticle1 = particles.Emitter(0,0,Misc.resolveFile('particles_firework1.ini'))		-- particles for the firework!
local fireworkParticle2 = particles.Emitter(0,0,Misc.resolveFile('particles_firework2.ini'))		-- ^

local hanabihai = {}
local npcIDs = {}

local npcManager = require("npcManager")

registerEvent(hanabihai,"onDraw")

function hanabihai.register(id)
	npcManager.registerEvent(id, hanabihai, "onTickNPC")
	--npcManager.registerEvent(npcID, hanabihai, "onTickEndNPC")
	npcManager.registerEvent(id, hanabihai, "onDrawNPC")
	--registerEvent(hanabihai, "onNPCHarm")
	npcIDs[id] = true
end

function hanabihai.explodeSegment(v)
	-- Explodes the top most segment of the firework Fella. The top part will fall off with the first coloured segment. Also changes the npc's height accordingly.
	if not v.data.segmentCount then return end
	local data = v.data
	if data.segmentCount == 1 then	-- makes the last explosion and kills the npc
		Effect.spawn(825,v.x+v.width*0.5,v.y+v.height+8,data.segmentType[0])
		v:kill()
	else	-- reduces the top segment
		-- one segment less
		data.segmentCount = data.segmentCount - 1
		Effect.spawn(824,v.x + v.width * 0.5, v.y + (v.height) - 16 + 5 - data.segmentCount * 10,data.segmentType[data.segmentCount]+1)
		local effect = Effect.spawn(10,v.x, v.y + (v.height) - 24 - data.segmentCount * 10)
		effect.speedY = -4
		v.height = data.baseHeight + (data.segmentCount) * 10
		v.y = v.y + 10
	end
end

function hanabihai.drawParticles(x,y,colourType,colour)
	-- Draws particles for the explosion. Spawns 12 of each particle type and gives them a speed in the direction of each full hour on a clock
	local particleColour = Color.white
	if colourType == 4 then
		particleColour = colour			-- it's the custom made colour
	elseif colourType == 1 then
		particleColour = Color.parse("#ff5389")		-- magenta colour
	elseif colourType == 2 then
		particleColour = Color.parse("#25ccff") 	-- blue colour
	else
		particleColour = Color.parse("#ffda47") 	-- if it's yellow (or all goes wrong), make it just yellow
	end
	for index = 0, 11 do	-- for each direction: spawn one particle
		local pspeedX = math.cos(index*math.pi / 6)
		local pspeedY = math.sin(index*math.pi / 6)	-- I thought you shouldn't sin...
		fireworkParticle1:setParam("speedX",pspeedX * 200)
		fireworkParticle1:setParam("speedY",pspeedY * 200)
		fireworkParticle1:setParam("col",particleColour)
		fireworkParticle1.x = x
		fireworkParticle1.y = y
		fireworkParticle1:Emit(1)
		fireworkParticle2:setParam("speedX",pspeedX * 100)
		fireworkParticle2:setParam("speedY",pspeedY * 100)
		fireworkParticle2:setParam("col",particleColour)
		fireworkParticle2.x = x
		fireworkParticle2.y = y
		fireworkParticle2:Emit(1)
		--Misc.dialog(speedX)
		
	end
end

function hanabihai.onTickNPC(v)
	local data = v.data
	local settings = data._settings
	
	if not data.segmentCount then
	--[[	Initialize all the vars required.
			the selected colour will be assigned per segment.
	]]--
		data.segmentType = {}
		data.segmentColor = {}
		if #settings.segmentData > 0 then			-- assignment via the good new segment list
			data.segmentCount = #settings.segmentData
			local i = 0
			for k, segment in ipairs(settings.segmentData) do
				if segment.useCustom then
					data.segmentType[i] = 4
					data.segmentColor[i] = Color.parse(segment.customColour) or Color.white
				else
					data.segmentType[i] = math.max(segment.defaultColour,1) or 1
					data.segmentColor[i] = Color.white
				end
				i = i + 1
			end
		else
			if data._settings.segmentCount then	-- assignment via the bad old line edits. (Only used for backwards compatibility)
				data.segmentCount = data._settings.segmentCount
			else
				data.segmentCount = 3	-- the default
			end
			
			local ColourSettings = settings.colourSet
			local i = 0
			for word in string.gmatch(ColourSettings,"%S+") do
				if string.find(word,"0") then	-- if it's a hex code, assign a custom colour
					data.segmentType[i] = 4
					data.segmentColor[i] = Color.fromHex(word)
				else							-- if it's a number, use a preset colour on the spritesheet
					data.segmentType[i] = word + 1 - 1	-- hmmm tasty spaghetti code (turns the string into a number)
					data.segmentColor[i] = Color.white
				end
				i = i+1
			end
		
		end
		v.data.priority = -75	-- render priority, so it renders behind the ground when coming from a generator
		data.frame = 0			-- the frame of the walking animation (can be 0 or 1)
		data.framecounter = 0	-- counts down to 0 and changes sprites
		if v.id == 824 then
			data.baseHeight = 24
			v.height = data.baseHeight + (data.segmentCount) * 10
			v.y = v.y - (v.height - 52)
		else
			data.baseHeight = 16
			v.height = data.baseHeight + (data.segmentCount) * 10
			v.y = v.y - (v.height - 46)
		end
	end
	if v.generatorType == 1 and v.layerName == "Default" then	-- weird check, I know but it checks whether an npc is coming from a generator
		v.data.priority = -75									-- and if so, make it render behind blocks
	else
		v.data.priority = -45
	end
end

function hanabihai.onDrawNPC(v)	
	if v.isHidden or (not v.data.initialized) or not v.data.segmentCount then return end
	local data = v.data
	
	if not data.hit then
	-- Draw the base if it's not harmed
		Graphics.drawBox{			-- draw the base
			texture      = basesprites,
			sceneCoords  = true,
			x            = v.x + (v.width / 2),
			y            = v.y + (v.height) - 12,
			width        = 30 * - v.direction,
			height       = 24,
			sourceX      = 15  * (data.segmentType[0]-1),
			sourceY      = 12 * data.frame,
			sourceWidth  = 15 ,
			sourceHeight = 12,
			centered     = true,
			priority     = data.priority,
			color        = data.segmentColor[0] .. 1,--playerOpacity,
			rotation     = 0,
		}
		if data.segmentType[0] == 4 then		-- draw an overlay so the not recolourable parts are not getting recoloured!
			Graphics.drawBox{			-- draw the base
				texture      = baseoverlaysprites,
				sceneCoords  = true,
				x            = v.x + (v.width / 2),
				y            = v.y + (v.height) - 12,
				width        = 30 * - v.direction,
				height       = 24,
				sourceX      = 0,
				sourceY      = 12 * data.frame,
				sourceWidth  = 15,
				sourceHeight = 12,
				centered     = true,
				priority     = data.priority + 1,
				color        = Color.white .. 1,--playerOpacity,
				rotation     = 0,
			}
		end
		data.baseHeight = 22
	else
	-- draw the base when harmed
		Graphics.drawBox{			-- draw the base
			texture      = hurtsprites,
			sceneCoords  = true,
			x            = v.x + (v.width / 2),
			y            = v.y + (v.height) - 8,
			width        = 30 * - v.direction,
			height       = 16,
			sourceX      = 15 * (data.segmentType[0]-1),-- * data.Offset[0],
			sourceY      = 0,-- * data.frame,
			sourceWidth  = 15,
			sourceHeight = 8,
			centered     = true,
			priority     = data.priority,
			color        = data.segmentColor[0] .. 1,--playerOpacity,
			rotation     = 0,
		}
		if data.segmentType[0] == 4 then-- draw the overlay yadda yadda
			Graphics.drawBox{			-- draw the base
				texture      = hurtoverlaysprites,
				sceneCoords  = true,
				x            = v.x + (v.width / 2),
				y            = v.y + (v.height) - 8,
				width        = 30 * - v.direction,
				height       = 16,
				sourceX      = 0,-- * data.Offset[0],
				sourceY      = 0,-- * data.frame,
				sourceWidth  = 15,
				sourceHeight = 8,
				centered     = true,
				priority     = data.priority + 1,
				color        = Color.white .. 1,--playerOpacity,
				rotation     = 0,
			}
		end
		data.baseHeight = 16
	end
	
	for segment = 1, data.segmentCount do
		--[[	Draws each segment on top of the base  ]]
		if segment == data.segmentCount then
			data.segmentType[segment] = 0
			data.segmentColor[segment] = Color.white
		end
		Graphics.drawBox{			-- draw one segment of the Firework Fella
			texture      = segmentsprites,
			sceneCoords  = true,
			x            = v.x + (v.width / 2),
			y            = v.y + (v.height) - data.baseHeight + 5 - segment * 10 - 2 * data.frame,
			width        = 30 * -v.direction,
			height       = 10,
			sourceX      = 0,
			sourceY      = 5 * data.segmentType[segment],
			sourceWidth  = 15,
			sourceHeight = 5,
			centered     = true,
			priority     = data.priority,
			color        = data.segmentColor[segment] .. 1,
			rotation     = 0,
		}
		if data.segmentType[segment] == 4 then	-- draw the white and black overlay for the individual segments
			Graphics.drawBox{			-- draw one segment of the Firework Fella
				texture      = segmentoverlaysprites,
				sceneCoords  = true,
				x            = v.x + (v.width / 2),
				y            = v.y + (v.height) - data.baseHeight + 5 - segment * 10 - 2 * data.frame,
				width        = 30 * -v.direction,
				height       = 10,
				sourceX      = 0,
				sourceY      = 0,
				sourceWidth  = 15,
				sourceHeight = 5,
				centered     = true,
				priority     = data.priority + 1,
				color        = Color.white .. 1,
				rotation     = 0,
			}
		end
	end

end

function hanabihai.onDraw()	-- to draw particles
	fireworkParticle1:draw(1)
	fireworkParticle2:draw(1)
end

return hanabihai