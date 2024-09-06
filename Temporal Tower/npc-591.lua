 local onlinePlayNPC = require("scripts/onlinePlay_npc")

--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
}

onlinePlayNPC.onlineHandlingConfig[591] = {
	getExtraData = function(v)
		local data = v.data
        if not data.initialized then
            return nil
        end

        return {
            falling = data.falling,
            datatime = data.time,
			shake = data.shake,
			forcefall = data.forcefall,
			datax = data.x,
        }
    end,
    setExtraData = function(v,receivedData)
	local data = v.data
        if not data.initialized then
            return nil
        end

        data.falling = receivedData.falling
        data.time = receivedData.datatime
		data.shake = receivedData.shake
		data.forcefall = receivedData.forcefall
		data.x = receivedData.datax
    end,
}

--Gotta return the library table!
return sampleNPC