-- sinelayers 1.0
-- by Enjl
-- last updated August 22 2022

local sl = {}

local layers = {}

-- This script automatically works via layer names.
-- Layer names follow a specific format.
-- Examples:
-- sinea8f1x10y10d8 -- Y-Sway amplitude of 8 (* 8), frequency of 1 (second), x-movement of 10 (blocks right), y-movement of 10 blocks (down), over the course of 8 (seconds)
-- sinea0f1x-3y-8d1 -- No sway. Move 3 blocks left and 8 blocks up within one second.

-- Explanation:
-- The layer gets 2 sine motions applied. A constant y-sway, and a separate x/y movement motion. The former is controlled by a, f. The latter by x, y, d
-- sinea <- identifier
-- a[num] <- amplitude of the constant y-swaying motion, in quarter-blocks (pixels * 8)
-- f[num] <- frequency of the constant y-swaying motion, in seconds
-- x[num] <- horizontal distance travelled during movement motion, in blocks (pixels * 32)
-- y[num] <- vertical distance travelled during movement motion, in blocks (pixels * 32)
-- d[num] <- frequency (duration) of the movement motion, in seconds
local function addSineLayer(layer, amplitude, frequency, xMovement, yMovement, duration)
    table.insert(layers, {
        layer = layer,
        yAmp = amplitude * 4,
        yFreq = math.max(frequency, 0.1),
        xMult = xMovement * 16,
        yMult = yMovement * 16,
        xFreq = math.max(duration, 0.1)
    })
end

function sl.onStart()
    for k,l in ipairs(Layer.get()) do
        if l.name:find("sinea") then
            local amp = l.name:find("a")
            local freq = l.name:find("f")
            local x = l.name:find("x")
            local y = l.name:find("y")
            local duration = l.name:find("d")
            addSineLayer(
                l,
                tonumber(l.name:sub(amp+1, freq-1)),
                tonumber(l.name:sub(freq+1, x-1)),
                tonumber(l.name:sub(x+1, y-1)),
                tonumber(l.name:sub(y+1, duration-1)),
                tonumber(l.name:sub(duration+1))
            )
        end
    end
end

local timer = 0
local add = math.pi/64.1 * 4

function sl.onReset()
    timer = 0
end

function sl.onTick()
    if not Layer.isPaused() then
        local oldTimer = timer
        timer = timer + add
        for k,v in ipairs(layers) do
            local oldAmp = math.sin(oldTimer / v.yFreq);
            local oldMove = math.cos(oldTimer / v.xFreq)
            local newAmp = math.sin(timer / v.yFreq)
            local newMove = math.cos(timer / v.xFreq)
            v.layer.speedX = -(newMove - oldMove) * v.xMult
            v.layer.speedY = -(newMove - oldMove) * v.yMult + (-(newAmp - oldAmp) * v.yAmp)
        end
    end
end

registerEvent(sl, "onStart")
registerEvent(sl, "onTick")
registerEvent(sl, "onReset")

return sl