local mq = require('mq')
local utils = require('utils')
local commands = require('commands')
local gui = require('gui')
local nav = require('nav')
local tank = require('tank')
local assist = require('assist')

local class = mq.TLO.Me.Class()
if class ~= "Warrior" then
    print("This script is only for Warrior.")
    mq.exit()
end

local currentLevel = mq.TLO.Me.Level()

utils.PluginCheck()

mq.cmd('/assist off')

mq.imgui.init('controlGUI', gui.controlGUI)

commands.init()
commands.initALL()

local toggleboton = gui.botOn or false

local function returnChaseToggle()
    if gui.botOn and gui.returntocamp and not toggleboton then
        if nav.campLocation == nil then
            nav.setCamp()
            toggleboton = true
        end
    elseif not gui.botOn and toggleboton then
        nav.clearCamp()
        toggleboton = false
    end
end

utils.loadTankConfig()

while gui.controlGUI do

    returnChaseToggle()

    if gui.botOn then

        utils.monitorNav()

        if gui.tankOn then
            tank.tankRoutine()
        elseif gui.assistOn then
            assist.assistRoutine()
        end
    end

    mq.doevents()
    mq.delay(100)
end