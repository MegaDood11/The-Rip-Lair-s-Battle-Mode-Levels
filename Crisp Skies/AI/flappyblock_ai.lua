--[[
	
	CARRYABLE ROCKET BLOCK
	Custom SMBX2 NPC by FNC2002
	Concept art and GFX by FNC2002

	-------------------------------
	BEHAVIOR
	- A carryable block in a similar vein to the Propeller Block.
	- Holding the Jump or Spinjump key allows the player to fly
	upwards.
	- The rocket has limited fuel, so the player must land on the ground
	or place the block on the ground to recharge. Otherwise, the player
	cannot fly.

	NPC CONFIG
	- instantrefuel = false, -- Immediately refuel when touching the ground.
	- maxthrustspeed = 6, -- The max speed at which the player should fly upwards when using the rocket.
	- flapcount = 300, -- Number of frames that the thrusters can be used before it runs out. (Set to 0 or less for infinite)
	- onetimeuse = false -- The rocket does not refuel and it will break after all its fuel has been used up.
]]

--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local wingGFX = Graphics.loadImageResolved("flappyblock-wings.png")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local rocketBlock = {}

function rocketBlock.register(id)
	npcManager.registerEvent(id, rocketBlock, "onTickEndNPC")
	npcManager.registerEvent(id, rocketBlock, "onDrawNPC")
end

function rocketBlock.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.flapcount = NPC.config[v.id].flapcount
		data.flaps = data.flapcount
		data.isFlapping = 0
		data.isFlappingTimer = 0
		data.isRefueling = false
		data.waitTimer = 2
		data.slashTimer = 0
		data.bar = Sprite.bar{
			x = 0,
			y = 0,
			width = 32,
			height = 8,
			pivot = Sprite.align.TOP,
			value = 1,
		}
		data.barcolor = Color.green
	end

	--Depending on the NPC, these checks must be handled differently

	
	-- Put main AI below here
	-- Code that makes the NPC friendly and makes it talk. This is a test for verifying that your code runs.
	-- NOTE: If you have no code to put here, comment out the registerEvent line for onTickNPC.
	if v.heldPlayer then
		data.waitTimer = 2
		local held = v.heldPlayer
		if (held.keys.jump == KEYS_PRESSED or held.keys.altJump == KEYS_PRESSED) and not held:isGroundTouching() then
			data.isRefueling = false
			if (data.flaps > 0 or NPC.config[v.id].flapcount <= 0) then
				--held.isOnGround = false
				held:mem(0x11C,FIELD_WORD,Defines.jumpheight)
				data.flaps = data.flaps - 1
				data.isFlapping = 1
				data.isFlappingTimer = 10
				SFX.play(50)
				Animation.spawn(10,v.x,v.y+v.height/2)
			end
		end

		if held:isGroundTouching() and held.speedY >= 0 then
			if data.flaps < data.flapcount then
				if NPC.config[v.id].onetimeuse == false and NPC.config[v.id].flapcount > 0 then
					if NPC.config[v.id].instantrefuel == true then
						data.flaps = data.flapcount
						SFX.play(59)
					else
						if lunatime.tick() % 32 == 0 and data.flaps < data.flapcount then
							data.flaps = data.flaps + 1
							SFX.play(14)
						end
						data.isRefueling = true
					end
				end
			else
				data.isRefueling = false
			end
		end
	else
		if data.waitTimer > 0 then
			data.waitTimer = data.waitTimer - 1
		end
	end

	if v.collidesBlockBottom and not v.heldPlayer and data.waitTimer <= 0 then
		if data.flaps < data.flapcount then
			if NPC.config[v.id].onetimeuse == false and NPC.config[v.id].flapcount > 0 then
				if NPC.config[v.id].instantrefuel == true then
					data.flaps = data.flapcount
					SFX.play(59)
				else
					if lunatime.tick() % 32 == 0 and data.flaps < data.flapcount then
						data.flaps = data.flaps + 1
						SFX.play(14)
					end
					data.isRefueling = true
				end
			end
		else
			data.isRefueling = false
		end
	end

	--Text.print(data.isRefueling,100,100)

	if data.isRefueling == true then
		if data.flaps == math.floor(data.flapcount) then
			SFX.play(59)
			data.isRefueling = false
		end		
	end

	if data.flaps == 1 and lunatime.tick() % 2 == 0 and NPC.config[v.id].onetimeuse and NPC.config[v.id].flapcount > 1 and v.heldPlayer then
		SFX.play(26)
	end

	if data.flaps == 0 and NPC.config[v.id].onetimeuse == true and NPC.config[v.id].flapcount > 0 then
		SFX.play(22)
		Effect.spawn(v.id,v.x+v.width/4,v.y+v.height/4)
		Effect.spawn(10,v.x,v.y)
		v:kill(9)
	end
	
	-- Animation frame handling
	if NPC.config[v.id].flapcount > 0 then
		if data.flaps >= math.floor(data.flapcount) then
			data.barcolor = Color.green
		elseif data.flaps < math.floor(data.flapcount) and data.flaps >= math.floor(data.flapcount * 0.8) then
			data.barcolor = Color.green
		elseif data.flaps < math.floor(data.flapcount * 0.8) and data.flaps >= math.floor(data.flapcount * 0.6) then
			data.barcolor = Color.yellow
		elseif data.flaps < math.floor(data.flapcount * 0.6) and data.flaps >= math.floor(data.flapcount * 0.4) then
			data.barcolor = Color.yellow
		elseif data.flaps < math.floor(data.flapcount * 0.4) and data.flaps >= math.floor(data.flapcount * 0.2) then
			data.barcolor = Color.red
		elseif data.flaps < math.floor(data.flapcount * 0.2) and data.flaps > 0 then
			data.barcolor = Color.red
		else
			data.barcolor = Color.red
		end
		if data.flaps == data.flapcount then
			v.animationFrame = 0
		elseif data.flaps > 1 and data.flaps < data.flapcount then
			v.animationFrame = 1
		elseif data.flaps == 1 then
			v.animationFrame = 2
		elseif data.flaps == 0 then
			v.animationFrame = 3
		end
	else
		v.animationFrame = 0
	end

	-- Wings animation handling
	if data.isFlappingTimer > 0 then
		data.isFlappingTimer = data.isFlappingTimer - 1
	else
		data.isFlapping = 0
	end
	
	if data.slashTimer > 0 then data.slashTimer = data.slashTimer - 1 end

	-- Grab from the top code based on summonClosestNPC.lua by MegaDood & MrNameless
	if not v.heldPlayer then
		for _,p in ipairs(Player.get()) do
			if Colliders.collide(p,v) and (p.keys.run or p.keys.altRun) and p.holdingNPC == nil
			and p.character ~= CHARACTER_LINK and p.deathTimer == 0 and p.forcedState == 0 and p.mount == 0 then
				v.x = (p.x + p.width*0.5) - v.width*0.5
				v.y = (p.y + p.height*0.5) - v.height*0.5
				v.heldIndex = p.idx
				p:mem(0x154, FIELD_WORD, v.idx+1)
				SFX.play(23)

				if p.isDucking == true then p.isDucking = false end
			end

			-- Reimplemented the Link slash mechanics for Billy Gun
			if (Colliders.slash(p,v) or Colliders.downSlash(p,v)) and data.slashTimer == 0 then
				data.slashTimer = 4
				v.speedX = p.direction * 3
				v.speedY = -5
				v.isProjectile = true
				SFX.play(9)
			end
		end
	end
end

function rocketBlock.onDrawNPC(v)
	local data = v.data
	if v.heldPlayer and data.flaps == 1 and lunatime.tick() % 8 <= 4 and NPC.config[v.id].onetimeuse and NPC.config[v.id].flapcount > 1 then
		npcutils.hideNPC(v)
	end
	if v.isValid and v.despawnTimer > 0 and v.forcedState == 0 then
		if data.isFlapping then
			Graphics.drawImageToSceneWP(
				wingGFX,
				v.x-v.width/1.35,
				v.y-v.height/4,
				0,
				40 * data.isFlapping,
				80,
				40,
				-65
			)
		end
	end

	if v.heldPlayer  then
		local held = v.heldPlayer

		if NPC.config[v.id].fueldisplay == true and data.bar and NPC.config[v.id].flapcount > 0  then
			data.bar:draw{barcolor = data.barcolor, sceneCoords = true }
			data.bar.x = held.x + held.width/2
			data.bar.y = held.y - 20
			data.bar.value = data.flaps / data.flapcount
		end
	else
		if data.bar then
			data.bar.x = 0
			data.bar.y = 0
		end
	end
end

onlinePlayNPC.onlineHandlingConfig[827] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			projectile = data.projectile,
			flapcount = data.flapcount,
			flaps = data.flaps,
			isFlapping = data.isFlapping,
			isFlappingTimer = data.isFlappingTimer,
			isRefueling = data.isRefueling,
			waitTimer = data.waitTimer,
			bar = data.bar,
			barcolor = data.barcolor,
			slashTimer = data.slashTimer,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.projectile = receivedData.projectile
		data.flapcount = receivedData.flapcount
		data.flaps = receivedData.flaps
		data.isFlapping = receivedData.isFlapping
		data.isFlappingTimer = receivedData.isFlappingTimer
		data.isRefueling = receivedData.isRefueling
		data.waitTimer = receivedData.waitTimer
		data.bar = receivedData.bar
		data.barcolor = receivedData.barcolor
		data.slashTimer = receivedData.slashTimer
	end,
}

--Gotta return the library table!
return rocketBlock