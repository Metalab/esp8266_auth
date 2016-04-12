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

	tmr.alarm(4, 2000, 0, function() -- measured ~25sec
		gpio.write(SWITCH,gpio.LOW)
		doorIsOpen = false
		donecb()
	end)
end
