local mq = require('mq')
local gui = require('gui')
local utils = require('utils')

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local assist = {}

function assist.assistRoutine()

    if not gui.botOn or not gui.assistMelee then
        return
    end

    -- Use reference location to find mobs within assist range
    local mobsInRange = utils.referenceLocation(gui.assistRange) or {}
    if #mobsInRange == 0 then
        return
    end

    -- Check if the main assist is a valid PC, is alive, and is in the same zone
    local mainAssistSpawn = mq.TLO.Spawn(gui.mainAssist)
    if mainAssistSpawn and mainAssistSpawn.Type() == "PC" and not mainAssistSpawn.Dead() then
        mq.cmdf("/assist %s", gui.mainAssist)
        mq.delay(200)  -- Short delay to allow the assist command to take effect
    else
        return
    end

    -- Re-check the target after assisting to confirm it's an NPC within range
    if not mq.TLO.Target() or (mq.TLO.Target() and  mq.TLO.Target.Type() ~= "NPC") then
        return
    end

    if mq.TLO.Target() and mq.TLO.Target.PctHPs() <= gui.assistPercent and mq.TLO.Target.Distance() <= gui.assistRange and not mq.TLO.Stick.Active() and not mq.TLO.Target.Mezzed() then
        if gui.stickFront then
            if mq.TLO.Navigation.Active() then
                mq.cmd('/nav stop')
                mq.delay(100)
            end
            mq.cmd("/stick moveback 0")
            mq.delay(100)
            mq.cmdf("/stick front %d uw", gui.stickDistance)
            mq.delay(100)
        elseif gui.stickBehind then
            if mq.TLO.Navigation.Active() then
                mq.cmd('/nav stop')
                mq.delay(100)
            end
            mq.cmd("/stick moveback 0")
            mq.delay(100)
            mq.cmdf("/stick behind %d uw", gui.stickDistance)
            mq.delay(100)
        elseif gui.stickSide then
            if mq.TLO.Navigation.Active() then
                mq.cmd('/nav stop')
                mq.delay(100)
            end
            mq.cmd("/stick moveback 0")
            mq.delay(100)
            mq.cmdf("/stick pin %d uw", gui.stickDistance)
            mq.delay(100)
        end

        while mq.TLO.Target() and mq.TLO.Target.Distance() > gui.stickDistance and mq.TLO.Stick.Active() do
            mq.delay(10)
        end

        if mq.TLO.Target() and not mq.TLO.Target.Mezzed() and mq.TLO.Target.PctHPs() <= gui.assistPercent and mq.TLO.Target.Distance() <= gui.assistRange and not mq.TLO.Me.Combat() then
            mq.cmd("/squelch /attack on")
        elseif mq.TLO.Target() and (mq.TLO.Target.Mezzed() or mq.TLO.Target.PctHPs() > gui.assistPercent or mq.TLO.Target.Distance() > (gui.assistRange + 30)) and mq.TLO.Me.Combat() then
            mq.cmd("/squelch /attack off")
        end
    end

    if mq.TLO.Target() and mq.TLO.Target.PctHPs() <= gui.assistPercent and mq.TLO.Target.Distance() <= gui.assistRange and mq.TLO.Stick() == "ON" and not mq.TLO.Target.Mezzed() and not mq.TLO.Me.Combat() then
        mq.cmd("/squelch /attack on")
    end

    while mq.TLO.Me.CombatState() == "COMBAT" and mq.TLO.Target() and not mq.TLO.Target.Dead() do

        if not gui.botOn and not gui.assistOn then
            return
        end

        if gui.switchWithMA then
            mq.cmd("/squelch /assist %s", gui.mainAssist)
        end

        -- Re-check the target after assisting to confirm it's an NPC within range
        if not mq.TLO.Target() or (mq.TLO.Target() and  mq.TLO.Target.Type() ~= "NPC") then
            return
        end

        if mq.TLO.Target() and not mq.TLO.Target.Mezzed() and mq.TLO.Target.PctHPs() <= gui.assistPercent and mq.TLO.Target.Distance() <= gui.assistRange then
            mq.cmd("/squelch /attack on")
        elseif mq.TLO.Target() and (mq.TLO.Target.Mezzed() or mq.TLO.Target.PctHPs() > gui.assistPercent or mq.TLO.Target.Distance() > (gui.assistRange + 30)) then
            mq.cmd("/squelch /attack off")
        end

        if mq.TLO.Target() and mq.TLO.Me.AbilityReady("Bash")() and mq.TLO.Me.Inventory('Offhand').Type() == "Shield" then
            debugPrint("Using Bash ability.")
            mq.cmd("/doability Bash")
            mq.delay(100)
        elseif mq.TLO.Target() and mq.TLO.Me.AbilityReady("Slam")() and mq.TLO.Me.Inventory('Offhand').Type() ~= "Shield" and mq.TLO.Me.Race() == "Ogre" then
            debugPrint("Using Slam ability.")
            mq.cmd("/doability Slam")
            mq.delay(100)
        end

        local lastStickDistance = nil

        if mq.TLO.Target() and mq.TLO.Stick.Active() then
            local stickDistance = gui.stickDistance -- current GUI stick distance
            local lowerBound = stickDistance * 0.9
            local upperBound = stickDistance * 1.1
            local targetDistance = mq.TLO.Target.Distance()
            
            -- Check if stickDistance has changed
            if lastStickDistance and lastStickDistance ~= stickDistance then
                lastStickDistance = stickDistance
                mq.cmdf("/squelch /stick moveback %s", stickDistance)
            end

            -- Check if the target distance is out of bounds and adjust as necessary
            if mq.TLO.Target() and not mq.TLO.Target.Dead() then
                if mq.TLO.Target() and targetDistance > upperBound then
                    mq.cmdf("/squelch /stick moveback %s", stickDistance)
                    mq.delay(100)
                elseif mq.TLO.Target() and targetDistance < lowerBound then
                    mq.cmdf("/squelch /stick moveback %s", stickDistance)
                    mq.delay(100)
                end
            end
        end

        if mq.TLO.Me.Combat() and not mq.TLO.Stick() then
            mq.cmd("/squelch /attack off")
        end

        if mq.TLO.Target() and mq.TLO.Target.Dead() or not mq.TLO.Target() then
            mq.cmd("/squelch /attack off")
            return
        end

    mq.delay(50)
    end
end

return assist