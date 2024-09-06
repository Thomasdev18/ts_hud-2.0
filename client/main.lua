local Config = lib.load('config')
local speedMultiplier = Config.speedType == "MPH" and 2.23694 or 3.6
local CAM_HEIGHT = 0.2
local currentColors = {
    voiceInactive = '#6c757d', voiceActive = '#ffd43b', voiceRadio = '#1c7ed6',
    health = '#099268', armor = '#74c0fc', oxygen = '#228be6',
    hunger = '#f08c00', thirst = '#1971c2', stress = '#ff6b6b',
}

-- State Variables
local playerState = {
    voiceMethod = false,
    showingVehicleHUD = false,
    showingPlayerHUD = false,
    showingCompass = false,
    isSeatbeltOn = false,
    isHarnessOn = false,
    nitroActive = false,
    nos = 0,
    stress = 0,
    camHeight = 0.0,
    camActive = false,
    camMoving = false,
    lastCrossroadUpdate = 0,
    lastCrossroadCheck = {}
}

-- Utility Functions
local function showNUI(action, shouldShow, focus)
    SetNuiFocus(focus, focus)
    SendNUIMessage({ action = action, data = shouldShow })
end

local function sendNUI(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function toggleSettingsMenu()
    showNUI('HUDSettings', true, true)
end

local function hideSettingsMenu()
    showNUI('HUDSettings', false, false)
    SetNuiFocus(false, false)
end

local function updatePlayerVoiceMethod(player)
    if playerState.voiceMethod ~= "radio" then
        playerState.voiceMethod = MumbleIsPlayerTalking(player) and "voice" or false
    end
    return playerState.voiceMethod
end

local function getHeadingText(heading)
    local directions = {'N', 'NW', 'W', 'SW', 'S', 'SE', 'E', 'NE'}
    local ranges = {30, 60, 120, 160, 210, 240, 310, 330}
    for i, range in ipairs(ranges) do
        if heading < range or (i == #ranges and heading >= ranges[#ranges]) then
            return directions[i]
        end
    end
    return 'N'
end

local function updateCrossroads(vehicle)
    local currentTick = GetGameTimer()
    if currentTick - playerState.lastCrossroadUpdate > 1500 then
        local pos = GetEntityCoords(vehicle)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        playerState.lastCrossroadUpdate = currentTick
        playerState.lastCrossroadCheck = { GetStreetNameFromHashKey(street1), GetStreetNameFromHashKey(street2) }
    end
    return playerState.lastCrossroadCheck
end

local function getFuelLevel(vehicle)
    return GetVehicleFuelLevel(vehicle)
end

local function getSeatbeltStatus()
    return playerState.isSeatbeltOn
end

local function getBlurIntensity(stressLevel)
    for _, v in ipairs(Config.stress.blurIntensity) do
        if stressLevel >= v.min and stressLevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function getEffectInterval(stressLevel)
    for _, v in ipairs(Config.stress.effectInterval) do
        if stressLevel >= v.min and stressLevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

local function isWhitelistedWeaponStress(weapon)
    for _, v in ipairs(Config.stress.whitelistedWeapons) do
        if weapon == v then return true end
    end
    return false
end

local function startWeaponStressThread(weapon)
    if isWhitelistedWeaponStress(weapon) then return end
    playerState.hasWeapon = true

    CreateThread(function()
        while playerState.hasWeapon do
            if IsPedShooting(cache.ped) and math.random() <= Config.stress.chance then
                TriggerServerEvent('hud:server:GainStress', math.random(1, 5))
            end
            Wait(0)
        end
    end)
end

local function setupHealthArmour(minimap, barType)
    BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
    ScaleformMovieMethodAddParamInt(barType)
    EndScaleformMovieMethod()
end

local function handleCinematicAnim()
    playerState.camMoving = true
    setupHealthArmour(playerState.camActive and 3 or 0)
    local step = playerState.camActive and 0.01 or -0.01
    for i = 0, CAM_HEIGHT, step do
        playerState.camHeight = i
        Wait(10)
    end
    camMoving = false
end

AddEventHandler('ox_inventory:currentWeapon', function(currentWeapon)
    playerState.hasWeapon = false
    Wait(0)
    if currentWeapon then startWeaponStressThread(currentWeapon.hash) end
end)

local function saveHUDSettings()
    SetResourceKvp('playerHUDColors', json.encode(currentColors))
    SetResourceKvp('hudType', hudType)
    SetResourceKvp('hudPosition', position)
end

-- NUI Callbacks
RegisterNUICallback('updateHudType', function(data, cb)
    hudType = data.hudType
    saveHUDSettings()
    cb({ status = 'success', message = 'HUD type updated to ' .. data.hudType })
end)

RegisterNUICallback('updateHudPosition', function(data, cb)
    position = data.hudPosition
    saveHUDSettings()
    cb({ status = 'success', message = 'HUD position updated to ' .. data.hudPosition })
end)

RegisterNUICallback('updateColors', function(data, cb)
    currentColors = data.colors
    saveHUDSettings()
    cb({ status = 'success', message = 'Colors updated' })
end)

RegisterNUICallback('hideHudMenu', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('toggleCinematicBars', function(data, cb)
    playerState.camActive = data.enabled
    CreateThread(handleCinematicAnim)
    TriggerEvent('ts_hud:client:hideHUD')
    if not playerState.camActive then
        TriggerEvent('ts_hud:client:showHud')
    end
    hideSettingsMenu()
    cb({ status = 'success', message = 'Cinematic bars ' .. (data.enabled and 'disabled') })
end)

RegisterNUICallback('getCinematicBarsState', function(_, cb)
    cb({ enabled = playerState.camActive })
end)

-- Event Handlers
RegisterNetEvent('ts_hud:client:OpenHudMenu', toggleSettingsMenu)

RegisterNetEvent('ts_hud:client:hideHUD', function()
    showNUI('setVisiblePlayer', false, false)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if IsPedInVehicle(cache.ped, vehicle) and GetIsVehicleEngineRunning(vehicle) then
        showNUI('setVisibleVehicle', false, false)
    end
end)

RegisterNetEvent('ts_hud:client:showHud', function()
    showNUI('setVisiblePlayer', true, false)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if IsPedInVehicle(cache.ped, vehicle) and GetIsVehicleEngineRunning(vehicle) then
        showNUI('setVisibleVehicle', true, false)
    end
end)

RegisterNetEvent('hud:client:LoadMap', function()
    Wait(50)
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local minimapOffset = (1920 / 1080 > resolutionX / resolutionY) and ((1920 / 1080 - resolutionX / resolutionY) / 3.6) - 0.008 or 0

    RequestStreamedTextureDict("squaremap", false)
    while not HasStreamedTextureDictLoaded("squaremap") do
        Wait(150)
    end

    SetMinimapClipType(0)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")

    SetMinimapComponentPosition("minimap", "L", "B", -0.006 + minimapOffset, -0.040, 0.1638, 0.183)
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.0, 0.128, 0.20)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.017 + minimapOffset, 0.030, 0.267, 0.300)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
    SetRadarZoom(1000)
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function()
    playerState.isSeatbeltOn = not playerState.isSeatbeltOn
end)

RegisterNetEvent('hud:client:UpdateNitrous', function(_, nitroLevel, bool)
    playerState.nos = nitroLevel
    playerState.nitroActive = bool
end)

AddStateBagChangeHandler('stress', ('player:%s'):format(cache.serverId), function(_, _, value)
    playerState.stress = value
end)

AddEventHandler("pma-voice:radioActive", function(radioTalking)
    playerState.voiceMethod = radioTalking and 'radio' or false
end)

-- Keybind Registration
lib.addKeybind({
    name = 'openhud',
    description = 'Opens HUD Settings',
    defaultKey = Config.hudKeybind,
    defaultMapper = 'keyboard',
    onPressed = toggleSettingsMenu,
})

-- nitro for qbox
if GetResourceState('qbx_nitro') == 'started' then
    qbx.entityStateHandler('nitroFlames', function(veh, netId, value)
        local plate = qbx.string.trim(GetVehicleNumberPlateText(veh))
        local cachePlate = qbx.string.trim(GetVehicleNumberPlateText(cache.vehicle))
        if plate ~= cachePlate then return end
        nitroActive = value
    end)
    
    qbx.entityStateHandler('nitro', function(veh, netId, value)
        local plate = qbx.string.trim(GetVehicleNumberPlateText(veh))
        local cachePlate = qbx.string.trim(GetVehicleNumberPlateText(cache.vehicle))
        if plate ~= cachePlate then return end
        nos = value
    end)
end

-- Stress Management
if Config.stress.enableStress then
    CreateThread(function()
        while true do
            if LocalPlayer.state.isLoggedIn and cache.vehicle then
                local vehClass = GetVehicleClass(cache.vehicle)
                local speed = GetEntitySpeed(cache.vehicle) * speedMultiplier

                if vehClass ~= 13 and vehClass ~= 14 and vehClass ~= 15 and vehClass ~= 16 and vehClass ~= 21 then
                    local stressSpeed = (vehClass == 8 or not playerState.isSeatbeltOn) and Config.stress.minForSpeedingUnbuckled or Config.stress.minForSpeeding
                    if speed >= stressSpeed then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                end
            end
            Wait(10000)
        end
    end)

    CreateThread(function()
        while true do
            local effectInterval = getEffectInterval(playerState.stress)
            if playerState.stress >= 100 then
                local blurIntensity = getBlurIntensity(playerState.stress)
                local fallRepeat = math.random(2, 4)
                local ragdollTimeout = fallRepeat * 1750
                TriggerScreenblurFadeIn(1000.0)
                Wait(blurIntensity)
                TriggerScreenblurFadeOut(1000.0)

                if not IsPedRagdoll(cache.ped) and IsPedOnFoot(cache.ped) and not IsPedSwimming(cache.ped) then
                    local forwardVector = GetEntityForwardVector(cache.ped)
                    SetPedToRagdollWithFall(cache.ped, ragdollTimeout, ragdollTimeout, 1, forwardVector.x, forwardVector.y, forwardVector.z, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                end

                Wait(1000)
                for _ = 1, fallRepeat, 1 do
                    Wait(750)
                    DoScreenFadeOut(200)
                    Wait(1000)
                    DoScreenFadeIn(200)
                    TriggerScreenblurFadeIn(1000.0)
                    Wait(blurIntensity)
                    TriggerScreenblurFadeOut(1000.0)
                end
            elseif playerState.stress >= Config.stress.minForShaking then
                local blurIntensity = getBlurIntensity(playerState.stress)
                TriggerScreenblurFadeIn(1000.0)
                Wait(blurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
            Wait(effectInterval)
        end
    end)
end

-- Fuel and Seatbelt Threads
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn and cache.vehicle and not IsThisModelABicycle(GetEntityModel(cache.vehicle)) then
            if getFuelLevel(cache.vehicle) <= 20 and Config.isLowFuelChecked then
                lib.notify({
                    description = 'Vehicle is low on fuel!',
                    type = 'error',
                })
                Wait(60000)
            end
        end
        Wait(10000)
    end
end)

CreateThread(function()
    local wasPauseMenuActive = IsPauseMenuActive()
    while true do
        if IsPauseMenuActive() then
            if not wasPauseMenuActive then
                wasPauseMenuActive = true
                if playerState.camActive then
                    playerState.camActive = false
                    DisplayRadar(not playerState.camActive)
                    DrawRect(0.0, 0.0, 2.0, playerState.camHeight, 0, 0, 0, 0)
                end
            end
        else
            if wasPauseMenuActive then
                wasPauseMenuActive = false
            end
            if playerState.camActive then
                DisplayRadar(not playerState.camActive)
                for i = 0, 1.0, 1.0 do
                    DrawRect(0.0, 0.0, 2.0, playerState.camHeight, 0, 0, 0, 255)
                    DrawRect(0.0, i, 2.0, playerState.camHeight, 0, 0, 0, 255)
                end
            end
        end
        Wait(0)
    end
end)

-- Main HUD Thread
CreateThread(function()
    local savedColors = GetResourceKvpString('playerHUDColors')
    currentColors = savedColors and json.decode(savedColors) or currentColors

    hudType = GetResourceKvpString('hudType') or Config.hudSettings.hudType
    position = GetResourceKvpString('hudPosition') or Config.hudSettings.hudPosition

    while true do
        if not IsPauseMenuActive() and LocalPlayer.state.isLoggedIn then
            local stamina = 100 - GetPlayerSprintStaminaRemaining(cache.playerId)
            local PlayerData = Config.core.Functions.GetPlayerData()

            if not playerState.showingPlayerHUD then
                DisplayRadar(false)
                showNUI('setVisiblePlayer', true, false)
                playerState.showingPlayerHUD = true
            end

            if IsEntityInWater(cache.ped) then
                stamina = (GetPlayerUnderwaterTimeRemaining(cache.playerId) * 10) - 300
            end

            sendNUI('player', {
                health = math.ceil(GetEntityHealth(cache.ped) - 100),
                stress = playerState.stress,
                armor = math.ceil(GetPedArmour(cache.ped)),
                thirst = math.ceil(PlayerData.metadata.thirst),
                hunger = math.ceil(PlayerData.metadata.hunger),
                oxygen = stamina or 0,
                voice = LocalPlayer.state.proximity.distance,
                talking = updatePlayerVoiceMethod(cache.playerId),
                colors = currentColors,
                hudType = hudType,
                hudPosition = position
            })

            if cache.vehicle and GetIsVehicleEngineRunning(cache.vehicle) then
                DisplayRadar(true)
                if not playerState.showingVehicleHUD then
                    showNUI('setVisibleVehicle', true, false)
                    TriggerEvent('hud:client:LoadMap')
                    playerState.showingVehicleHUD = true
                end

                sendNUI('vehicle', {
                    speed = math.ceil(GetEntitySpeed(cache.vehicle) * speedMultiplier),
                    gear = GetVehicleCurrentGear(cache.vehicle),
                    speedType = Config.speedType,
                    seatbeltOn = getSeatbeltStatus(),
                    streetName1 = updateCrossroads(cache.vehicle)[1],
                    streetName2 = updateCrossroads(cache.vehicle)[2],
                    heading = getHeadingText(GetEntityHeading(cache.vehicle)),
                    engineHealth = math.ceil(GetVehicleEngineHealth(cache.vehicle) / 10),
                    fuel = math.ceil(GetVehicleFuelLevel(cache.vehicle)),
                    nitrous = playerState.nos,
                    isInVehicle = true,
                })
                Wait(300)
            else
                if playerState.showingVehicleHUD then
                    DisplayRadar(false)
                    showNUI('setVisibleVehicle', false, false)
                    playerState.showingVehicleHUD = false
                end
                Wait(300)
            end
        else
            if playerState.showingPlayerHUD then
                showNUI('setVisiblePlayer', false, false)
                showNUI('setVisibleVehicle', false, false)
                playerState.showingVehicleHUD = false
                playerState.showingPlayerHUD = false
            end
            Wait(500)
        end
    end
end)
