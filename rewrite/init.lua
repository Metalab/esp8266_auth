wifi.setmode(wifi.STATION)
wifi.sta.config("scannerroom","")
wifi.sta.setip({ip="10.20.30.18",netmask="255.255.0.0",gateway="10.20.30.1"})

dofile("doorcontrol.lua")
dofile("ibutton.lua")
