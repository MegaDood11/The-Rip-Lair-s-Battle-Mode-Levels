 local onlinePlayNPC = require("scripts/onlinePlay_npc")

onlinePlayNPC.onlineHandlingConfig[459] = {
	getExtraData = function(v)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		return {
			down = data.down,
			type = data.type,
			resttime = data.resttime,
			gravitymultiplier = data.gravitymultiplier,
			jumpspeed = data.jumpspeed,
			effect = data.effect,
			sound = data.sound,
			friendlyrest = data.friendlyrest,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		data.down = receivedData.down
		data.type = receivedData.type
		data.resttime = receivedData.resttime
		data.gravitymultiplier = receivedData.gravitymultiplier
		data.jumpspeed = receivedData.jumpspeed
		data.effect = receivedData.effect
		data.sound = receivedData.sound
		data.friendlyrest = receivedData.friendlyrest
	end,
}

onlinePlayNPC.onlineHandlingConfig[460] = {
	getExtraData = function(v)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		return {
			down = data.down,
			type = data.type,
			resttime = data.resttime,
			gravitymultiplier = data.gravitymultiplier,
			jumpspeed = data.jumpspeed,
			effect = data.effect,
			sound = data.sound,
			friendlyrest = data.friendlyrest,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		data.down = receivedData.down
		data.type = receivedData.type
		data.resttime = receivedData.resttime
		data.gravitymultiplier = receivedData.gravitymultiplier
		data.jumpspeed = receivedData.jumpspeed
		data.effect = receivedData.effect
		data.sound = receivedData.sound
		data.friendlyrest = receivedData.friendlyrest
	end,
}