--TODO: For player spawn, dont spawn (show loadscreen), until ClientReady is true
local PauseOpen = false
local ActiveCharacterData = {}


local function ClearUIFeed()
    Citizen.InvokeNative(0x6035E8FBCA32AC5E) --UiFeedClearAllChannels
end

local function preventWeaponSoftlock()
    CreateThread(function()
        while true do
            Wait(1)

            --Disable controller actions within the weapons wheel (This prevents a soft lock)
            DisableControlAction(0, 0x7DA48D2A, true)
            DisableControlAction(0, 0x9CC7A1A4, true)
        end
    end)
end

local function disableRandomLootPrompt()
    CreateThread(function()
        while true do
            Wait(0)

            -- Disable random loot prompts
            Citizen.InvokeNative(0xFC094EF26DD153FA, 2)
        end
    end)
end

local function setupCharacterMenuIdle()
    -- This thread handles menu idle animation
    Citizen.CreateThread(function()
        while true do
            Wait(0)
            local ped = PlayerPedId()

            if IsPauseMenuActive() and not PauseOpen then
                SetCurrentPedWeapon(ped, 0xA2719263, true) -- set unarmed
                SetCurrentPedWeapon(ped, GetHashKey("weapon_unarmed"))
                if not IsPedOnMount(ped) then
                    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_SIT_GROUND_READING_BOOK"), -1, true,
                        "StartScenario", 0, false)
                end
                PauseOpen = true
            end

            if not IsPauseMenuActive() and PauseOpen then
                ClearPedTasks(ped)
                Wait(4000)
                SetCurrentPedWeapon(ped, 0xA2719263, true) -- set unarmed
                SetCurrentPedWeapon(ped, GetHashKey("weapon_unarmed"))
                PauseOpen = false
            end
        end
    end)
end

--TODO: Despawn character and then ACTUALLY spawn on /spawn command.



--Global as the main.lua uses it during initial startup. (sooner the better for this to start.)
function StartCharacterEssentials()
    EventsAPI:RegisterEventListener("EVENT_CHALLENGE_GOAL_COMPLETE", ClearUIFeed)
    EventsAPI:RegisterEventListener("EVENT_CHALLENGE_REWARD", ClearUIFeed)
    EventsAPI:RegisterEventListener("EVENT_DAILY_CHALLENGE_STREAK_COMPLETED", ClearUIFeed)

    preventWeaponSoftlock()
end

----------------------------------
-- Character Position handling --
----------------------------------
local function startPositionSync()
    Citizen.CreateThread(function()
        while true do
            local result = RPCAPI.CallAsync("UpdatePlayerCoords", GetEntityCoords(PlayerPedId()))
            print(tostring(result))
            Wait(20000)
        end
    end)
end

----------------------------------
-- Character Spawn handling --
----------------------------------
local function SpawnHandler(character)
    ActiveCharacterData = character
    startPositionSync()

    if Config.IdleAnimation then setupCharacterMenuIdle() end
    if Config.DisableRandomLootPrompts then disableRandomLootPrompt() end
end

RegisterNetEvent("bcc:character:spawn")
AddEventHandler("bcc:character:spawn", SpawnHandler)