--[[ ESP8266 Door Control System

Copyright (c) 2015 Andreas Monitzer

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]
local SWITCH=5 -- GPIO14

gpio.mode(SWITCH,gpio.OUTPUT)
gpio.write(SWITCH,gpio.LOW)

local doorIsOpen = false

function isDoorOpen()
    return doorIsOpen
end

function doorOpen(donecb)
	doorIsOpen = true
	gpio.write(SWITCH,gpio.HIGH)

	tmr.alarm(4, 2000, 0, function()
		gpio.write(SWITCH,gpio.LOW)
		doorIsOpen = false
		donecb()
	end)
end
