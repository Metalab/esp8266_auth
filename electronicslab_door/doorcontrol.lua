--[[ ESP8266 Door Control System

Copyright (c) 2015 Andreas Monitzer

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]
local SWITCH = 7
local DOORUP = 6
local DOORDOWN = 0
local LOGOUTBUTTON = 5

gpio.mode(SWITCH,gpio.OUTPUT)
gpio.mode(DOORUP,gpio.OUTPUT)
gpio.mode(DOORDOWN,gpio.OUTPUT)
gpio.mode(LOGOUTBUTTON, gpio.INT, gpio.PULLUP)
gpio.write(SWITCH,gpio.HIGH)
gpio.write(DOORUP,gpio.HIGH)
gpio.write(DOORDOWN,gpio.HIGH)

local doorIsMoving = false

function doorUp(donecb)
    doorIsMoving = true
    gpio.write(SWITCH,gpio.LOW)
    gpio.write(DOORUP,gpio.LOW)
    gpio.write(DOORDOWN,gpio.HIGH)
    tmr.alarm(4, 27000, 0, function() -- measured ~25sec
        gpio.write(DOORUP,gpio.HIGH)
        gpio.write(SWITCH,gpio.HIGH)
        doorIsMoving = false
        donecb()
    end)
end

function doorDown(donecb)
    doorIsMoving = true
    gpio.write(SWITCH,gpio.LOW)
    gpio.write(DOORUP,gpio.HIGH)
    gpio.write(DOORDOWN,gpio.LOW)
    tmr.alarm(4, 27000, 0, function() -- measured ~25sec
        gpio.write(DOORDOWN,gpio.HIGH)
        gpio.write(SWITCH,gpio.HIGH)
        doorIsMoving = false
        donecb()
    end)
end

function isDoorMoving()
    return doorIsMoving
end

gpio.trig(LOGOUTBUTTON, "down", function()
    tmr.alarm(5, 200, 0, function() -- debounce
        if not doorIsMoving and gpio.read(LOGOUTBUTTON) == 0 then
            blink_led_stop()
            doorDown(function()
                blink_led()
            end)
        end
    end)
end)
