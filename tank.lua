local mq = require('mq')
local gui = require('gui')
local utils = require('utils')
local nav = require('nav')

local DEBUG_MODE = false
-- Debug print helper function
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local tank = {}
local charLevel = mq.TLO.Me.Level()
local previousNearbyNPCs = 0 -- Initialize to track changes in nearby NPC count

local function buildMobQueue(range)
    debugPrint("Building mob queue with range:", range)
    local zoneName = mq.TLO.Zone.ShortName() or "UnknownZone"
    local ignoreList = utils.tankConfig[zoneName] or {}
    local globalIgnoreList = utils.tankConfig.globalIgnoreList or {}

    -- Filter mobs within range and not ignored
    local mobs = mq.getFilteredSpawns(function(spawn)
        local mobName = spawn.CleanName() or ""
        local isPlayerPet = spawn.Owner() and spawn.Owner.Type() == "PC"
        local isIgnored = ignoreList[mobName] or globalIgnoreList[mobName]

        return spawn.Type() == "NPC" and
               (spawn.Distance() or math.huge) <= range and
               not isPlayerPet and
               not spawn.Dead() and
               spawn.LineOfSight() and
               not isIgnored
    end)

    -- Sort mobs by priority: PctHPs (ascending), Named, then Level (descending)
    table.sort(mobs, function(a, b)
        local aPctHPs = a.PctHPs() or 100
        local bPctHPs = b.PctHPs() or 100
        local aNamed = a.Named() or false
        local bNamed = b.Named() or false
        local aLevel = a.Level() or 0
        local bLevel = b.Level() or 0

        if aPctHPs ~= bPctHPs then
            return aPctHPs < bPctHPs -- prioritize lower HP percentage
        elseif aNamed ~= bNamed then
            return aNamed -- prioritize named mobs
        else
            return aLevel > bLevel -- then by level, descending
        end
    end)

    debugPrint("Mob queue built with", #mobs, "mobs in range")
    return mobs
end

function tank.tankRoutine()
    if not gui.botOn and not gui.tankOn then
        debugPrint("Bot or melee mode is off; exiting combat loop.")
        mq.cmd("/squelch /attack off")
        mq.delay(100)
        mq.cmd("/squelch /stick off")
        mq.delay(100)
        mq.cmd("/squelch /nav off")
        return
    end

    local stickDistance = gui.stickDistance
    local lowerBound = stickDistance * 0.9
    local upperBound = stickDistance * 1.1

    while true do
        if not gui.botOn and not gui.tankOn then
            debugPrint("Bot or melee mode is off; exiting combat loop.")
            mq.cmd("/squelch /attack off")
            mq.delay(100)
            mq.cmd("/squelch /stick off")
            mq.delay(100)
            mq.cmd("/squelch /nav off")
            return
        end

        local nearbyNPCs = mq.TLO.SpawnCount(string.format('npc radius %d los', gui.tankRange))() or 0
        local mobsInRange = {}

        if nearbyNPCs > 0 then
        mobsInRange = buildMobQueue(gui.tankRange)
        end

        if #mobsInRange == 0 then
            debugPrint("No mobs in range.")

            if gui.travelTank then
                if mq.TLO.Navigation.Paused() then
                    debugPrint("Resuming navigation.")
                    mq.cmd("/squelch /nav pause")
                    mq.delay(100)
                end
            end

            if mq.TLO.Me.Combat() then
                debugPrint("Exiting combat mode.")
                mq.cmd("/squelch /attack off")
                mq.delay(100)
                return
            end

            return
        end

        local target = table.remove(mobsInRange, 1)
        debugPrint("Target:", target)

        if target and target.Distance() ~= nil and target.Distance() <= gui.tankRange and (not mq.TLO.Target() or mq.TLO.Target.ID() ~= target.ID()) and target.LineOfSight() then
            mq.cmdf("/target id %d", target.ID())
            mq.delay(300)
            debugPrint("Target set to:", target.CleanName())
        end

        if not mq.TLO.Target() or (mq.TLO.Target() and mq.TLO.Target.ID() ~= target.ID()) then
            debugPrint("No target selected; exiting combat loop.")
            return
        elseif mq.TLO.Target() and mq.TLO.Target.Distance() ~= nil and mq.TLO.Target.Distance() <= gui.tankRange and mq.TLO.Target.LineOfSight() and not mq.TLO.Stick.Active() then
         debugPrint("Not stuck to target; initiating stick command.")

            -- Stop or pause navigation depending on the travelTank setting
            if mq.TLO.Navigation.Active() and not mq.TLO.Navigation.Paused() then
                if not gui.travelTank then
                    if mq.TLO.Navigation.Active() then
                        debugPrint("Stopping navigation.")
                        mq.cmd("/squelch /nav stop")
                    end
                else
                    debugPrint("Pausing navigation.")
                    mq.cmd('/nav pause')
                end
                mq.delay(100, function() return not mq.TLO.Navigation.Active() end)
            end

            debugPrint("Stick distance:", stickDistance)
            mq.cmdf("/stick front %d uw", stickDistance)
            mq.delay(100, function() return mq.TLO.Stick.Active() end)
        end
        

        if mq.TLO.Target() and mq.TLO.Me.Combat() ~= nil and not mq.TLO.Me.Combat() and mq.TLO.Target.Distance() ~= nil and mq.TLO.Target.Distance() <= gui.tankRange and mq.TLO.Target.LineOfSight() ~= nil and mq.TLO.Target.LineOfSight() then
            debugPrint("Starting attack on target:", mq.TLO.Target.CleanName())
            mq.cmd("/squelch /attack on")
            mq.delay(100)
        end

        while mq.TLO.Me.CombatState() == "COMBAT" and mq.TLO.Target() and not mq.TLO.Target.Dead() do
            debugPrint("Combat state: ", mq.TLO.Me.CombatState())

            if not gui.botOn and not gui.tankOn then
                debugPrint("Bot or melee mode is off; exiting combat loop.")
                mq.cmd("/squelch /attack off")
                mq.delay(100)
                mq.cmd("/squelch /stick off")
                mq.delay(100)
                mq.cmd("/squelch /nav off")
                return
            end

            if mq.TLO.Target() and target and (mq.TLO.Target.ID() ~= target.ID() or mq.TLO.Target.Type() ~= "NPC") then
                mq.cmdf("/target id %d", target.ID())
                mq.delay(200)
            end

            if mq.TLO.Target() and not mq.TLO.Target.Dead() and not mq.TLO.Stick.Active() and mq.TLO.Target.Distance() <= gui.tankRange then
                mq.cmdf("/stick front %d uw", stickDistance)
                mq.delay(100, function() return mq.TLO.Stick.Active() end)
            end

            if mq.TLO.Target() and mq.TLO.Target.Distance() ~= nil and  mq.TLO.Target.Distance() <= gui.tankRange and mq.TLO.Target.LineOfSight() and not mq.TLO.Me.Combat() then
                debugPrint("Starting attack on target:", mq.TLO.Target.CleanName())
                mq.cmd("/squelch /attack on")
                mq.delay(100)
            end

            if mq.TLO.Target() and mq.TLO.Me.PctAggro() < 100 then
                if nav.campLocation then
                    local playerX, playerY = mq.TLO.Me.X(), mq.TLO.Me.Y()
                    local campX = tonumber(nav.campLocation.x) or 0
                    local campY = tonumber(nav.campLocation.y) or 0
                    local distanceToCamp = math.sqrt((playerX - campX)^2 + (playerY - campY)^2)

                    if gui.returntocamp and distanceToCamp > 100 then
                        debugPrint("Returning to camp location.")
                        if mq.TLO.Me.Combat() then
                            mq.cmd("/squelch /attack off")
                            mq.delay(100)
                        end
                        mq.cmd("/stick off")
                        mq.delay(100)
                        mq.cmdf("/nav loc %f %f %f", campY, campX, nav.campLocation.z or 0)
                        mq.delay(100)
                        while mq.TLO.Navigation.Active() do
                            mq.delay(50)
                        end
                        return
                    end
                end
            end

            if mq.TLO.Target() and not utils.FacingTarget() and not mq.TLO.Target.Dead() and mq.TLO.Target.LineOfSight() then
                debugPrint("Facing target:", mq.TLO.Target.CleanName())
                mq.cmd("/squelch /face fast")
                mq.delay(100)
            end

            if mq.TLO.Target() and mq.TLO.Target.Distance() ~= nil and mq.TLO.Target.Distance() <= gui.tankRange and mq.TLO.Target.LineOfSight() then

                if mq.TLO.Target() and mq.TLO.Me.AbilityReady("Taunt")() and mq.TLO.Me.PctAggro() < 100 then
                    debugPrint("Using Taunt ability.")
                    mq.cmd("/doability Taunt")
                    mq.delay(100)
                end

                if mq.TLO.Target() and mq.TLO.Target.Distance() <= gui.tankRange then
                    local slam = "Slam"
                    local kick = "Kick"
                    if mq.TLO.Target() and mq.TLO.Me.AbilityReady(slam) and mq.TLO.Me.Race() == "Ogre" then
                        mq.cmdf('/doability %s', slam)
                    elseif mq.TLO.Target() and mq.TLO.Me.AbilityReady(kick) and not mq.TLO.Me.Race() == "Ogre" then
                        mq.cmdf('/doability %s', kick)
                    end
                end
            end

            local lastStickDistance = nil

            if mq.TLO.Target() and mq.TLO.Stick.Active() then
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

            if target and target.Dead() then
                debugPrint("Target is dead; exiting combat loop.")
                break
            end

            mq.delay(50)
        end
    end
end

return tank