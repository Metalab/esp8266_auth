local pin=6 -- GPIO12
ow.setup(pin)

local learnMode = false
local newName = ""
local netState = 0
local learnModeSocket = nil
local usercount = -1
local testid = "XXXXX"
--local dummyid = "42-000000000000"

local password = "CHANGETHIS"

function list(c)
    openDatabase()
    local count = 0
    local out = ""
    while out ~= nil do
        line = readDatabaseline()
        out = line
        local name = ""
        if line ~= nil and count > 0 and line ~= "}\n" then
            --debug output
            --print(line)
            name = string.sub(line, 22)
            name = string.sub(name, 1, -4)
            name = name.."\n"
            c:send("["..count.."] "..name.."")
        end   
        count = count+1
    end
	closeDatabase()  

    usercount=count-3
    print(usercount)
    out = ""
    c:send("> ")
end

function setUsercount()
    openDatabase()
    local count = 0
    local out = ""
    while out ~= nil do
        line = readDatabaseline()
        out = line
        local name = ""
        count = count+1
    end
    closeDatabase()  
    
    usercount=count-3
end


function openDatabase()
	file.open( "database.lua", "r+" )
end


function rewriteDatabase(database)
	file.open( "database.lua", "w+" )
    file.write(database)
	closeDatabase()
end


function readDatabaseline()	
	--EOF gives nil value
	return file.readline()	
end


function closeDatabase()
	file.close()
end


function addtoDatabase(name, KeyID)
    local count = 0
    local writedb = ""
    
    openDatabase()
    while count < usercount+3 do
        line = readDatabaseline()
        if line == "}\n" then
            break
        end
        if line ~= nilr then
            --debug output
            --print(line)
            writedb = writedb..line
        end
        count = count+1
    end
    closeDatabase()
    
    writedb = writedb.."['"..KeyID.."']='"..name.."',\n}\n"
    rewriteDatabase(writedb)
    
    writedb = ""
    usercount = usercount+1
    print(usercount)
end


function removeFromDatabase(number)
	local count = 0
	local line = ""
	local newdb = ""
    local deleted = ""
    
    openDatabase()
    while count < usercount+4 do
        line = readDatabaseline()
        if count == number then
            deleted = line
        end
        
        if line ~= nil and count ~= number then
            --print(line)
            --print(count)
            newdb = newdb..line
        end
        count = count+1
    end
	closeDatabase()
    --Output for Debugging purposes
    --print(newdb)
    deleted = string.sub(deleted, 22)
    deleted = string.sub(deleted, 1, -4)
    deleted = deleted.."\n"
    print("deleted User: "..deleted)
    
    --rewrite Database without deleted user
    rewriteDatabase(newdb)
    
    newdb = ""
    
	usercount = usercount-1
end

function checkID(ID)
	--todo FIX checkID Function
    local back = false
    local id2 = ""
    local count = 0
    local line = ""
    openDatabase()
    while count < usercount+4 do
        line = readDatabaseline()
        id2 = string.match(line, ID)
        if id2 == ID then
            back = true
            break
        end
        count=count+1
    end
    closeDatabase()

    
    return back
end


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
					addtoDatabase(newName, id)
                    learnMode = false
                    netState = 0
                    learnModeSocket:send("Registered new device " .. id .. "\nHave a nice day!\n> ")
                else
                    --TODO check name function
                    local check = checkID(id)
                    --name = database[id]
                    if check then
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
            list(c)
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
            c:send("Which user to delete? Choose a Number\n")
            list(c)
            netState = 3
        elseif line == "check" then
            if checkID(testid) then
                c:send("SUCCESS!\n>")
            end
            netState = 0
        else
            c:send("Unrecognized command.\n> ")
            netState = 0
        end
    end,
    
    
    [2] = function(c, line)
        setUsercount()
        newName = line
        learnMode = true
        c:send("Learn mode activated. Please connect new iButton device.\n")
        learnModeSocket = c
    end,
    
    [3] = function(c, line)
        local delindex = tonumber(line)

        if delindex == nil then
            c:send("Please enter valid Indexnumber!\n")
            list(c)
            
        elseif delindex > 0 and delindex <= usercount then
           c:send("Got "..delindex.."\n> ")
           removeFromDatabase(delindex)
           c:send("User deleted!\n> ")
           netState = 0
        else
            c:send("Index out of bound exception, try again!\n")
            list(c)    
        end 
        
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
