--[[ ESP8266 Door Control System

Copyright (c) 2015 Andreas Monitzer

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]
local pin=6 -- GPIO12
ow.setup(pin)

local database = dofile('database.lua')
local learnMode = false
local newName = ""
local netState = 0
local learnModeSocket = nil
local delindex = -1
local index = 0
local delid = ""
local ibuttontable = {}

local password = "CHANGETHIS"


function reverse_str2hex(str)
    local i
    local result = {}
    local len = str:len()
    if len == 0 then
        return ""
    end
    for i = len, 1, -1 do
        table.insert(result,string.format("%02x", str:byte(i)))
    end
    return table.concat(result)
end

function saveDatabase()
	file.open("database.lua", "w+")
	file.writeline("return {")

	for k, v in pairs(database) do
		local escaped,count = string.gsub(v, "'", "\\'")
		file.writeline(string.format("['%s']='%s',", k, escaped))
	end

	file.writeline("}")
	file.close()
end

tmr.alarm(3, 100, 1, function()
    if not isDoorOpen() then
        local addr
        local name
        ow.reset_search(pin)
        addr = ow.search(pin)
        if (addr ~= nil) then
            local id = string.format("%02x",addr:byte(1)) .. "-" .. reverse_str2hex(addr:sub(2,addr:len()-1))
            print("Found device: " .. id)
            local crc = ow.crc8(addr:sub(1,7))
            if (crc == addr:byte(8)) then
                print("CRC OK")
				if learnMode then
					database[id] = newName
					saveDatabase()
					learnMode = false
					netState = 0
					learnModeSocket:send("Registered new device " .. id .. "\nHave a nice day!\n> ")
				else
	                name = database[id]
	                if name then
	                    print("Detected user " .. name)
	                    doorOpen(function()
	                    end)
	                end
				end
            else
                print("CRC FAILED")
            end
        end
    end
end)

local stateMachine = {
	[0] = function(c, line)
		if line == password then
			c:send("Please enter mode [add or del]:\n> ")
			netState = 1
		elseif line == "help" then
			c:send("Help is for the weak.\n> ")
		elseif line == "list" then
			c:send("Known users:\n")
			for k,v in pairs(database) do
				c:send(v .. "\n")
			end
			c:send("> ")
		elseif line == "exit" or line == "logout" or line == "logoff" then
			c:send("Thank you for flying with Metalab Airlines!\n")
			c:close()
		else
			c:send("Unrecognized command.\n> ")
		end
	end,
	
	[1] = function(c, line)
		if line == "add" then
			c:send("Please enter name:\n>")
			netState = 2
		elseif line == "del" then
			c:send("Which index to delete?\n")
			c:send("Known users:\n")
			for k,v in pairs(database) do
				ibuttontable[index] = k
				c:send("["..index.."] ".. v .. "\n")
				index++
			end
			c:send("> ")
			netState = 3
		else
			c:send("Unrecognized command.\n> ")
			netState = 0
	end,
	
	
	[2] = function(c, line)
		newName = line
		learnMode = true
		c:send("Learn mode activated. Please connect new iButton device.\n")
		learnModeSocket = c
	end,
	
	[3] = function(c, line)
		delindex = line
		delid = ibuttontable[delindex]
		database[delid] = nil
		saveDatabase()
		c:send("Index " delindex " deleted \n")
	end,
	
	[4] = function(c, line)
	end,
}

sv=net.createServer(net.TCP,40)
sv:listen(1337,function(c)
	c:send("Metalab Scannerdoor Control. Authorized personell only.\n> ")
	local buffer = ""
	c:on("receive", function(c, pl)
		buffer = buffer .. pl

		for line in buffer:gmatch("([^\r\n]*)\r?\n") do
			stateMachine[netState](c, line)
		end
		buffer = buffer:match("([^\r\n]*)$")
	end)
end)
