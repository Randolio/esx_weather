local CurrentWeather = Config.StartWeather
local lastWeather = CurrentWeather
local baseTime = Config.BaseTime
local timeOffset = Config.TimeOffset
local timer = 0
local freezeTime = Config.FreezeTime
local blackout = Config.Blackout
local blackoutVehicle = Config.BlackoutVehicle
local disable = Config.Disabled

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    ESX.PlayerLoaded = true
    disable = false
    TriggerServerEvent('esx-weathersync:server:RequestStateSync')
    TriggerServerEvent('esx-weathersync:server:RequestCommands')
end)

RegisterNetEvent('esx-weathersync:client:EnableSync', function()
    disable = false
    TriggerServerEvent('esx-weathersync:server:RequestStateSync')
end)

RegisterNetEvent('esx-weathersync:client:DisableSync', function()
	disable = true
	CreateThread(function()
		while disable do
			SetRainLevel(0.0)
			SetWeatherTypePersist('CLEAR')
			SetWeatherTypeNow('CLEAR')
			SetWeatherTypeNowPersist('CLEAR')
			NetworkOverrideClockTime(22, 0, 0)
			Wait(5000)
		end
	end)
end)

RegisterNetEvent('esx-weathersync:client:SyncWeather', function(NewWeather, newblackout)
    CurrentWeather = NewWeather
    blackout = newblackout
end)

exports('isBlackout', function()
    print(blackout) 
    return blackout 
end)

RegisterNetEvent('esx-weathersync:client:RequestCommands', function(isAllowed)
    if isAllowed then
        TriggerEvent('chat:addSuggestion', '/freezetime', Config.Translations.help.freezecommand, {})
        TriggerEvent('chat:addSuggestion', '/freezeweather', Config.Translations.help.freezeweathercommand, {})
        TriggerEvent('chat:addSuggestion', '/weather', Config.Translations.help.weathercommand, {
            { name=Config.Translations.help.weathertype, help=Config.Translations.help.availableweather }
        })
        TriggerEvent('chat:addSuggestion', '/blackout', Config.Translations.help.blackoutcommand, {})
        TriggerEvent('chat:addSuggestion', '/morning', Config.Translations.help.morningcommand, {})
        TriggerEvent('chat:addSuggestion', '/noon', Config.Translations.help.nooncommand, {})
        TriggerEvent('chat:addSuggestion', '/evening', Config.Translations.help.eveningcommand, {})
        TriggerEvent('chat:addSuggestion', '/night', Config.Translations.help.nightcommand, {})
        TriggerEvent('chat:addSuggestion', '/time', Config.Translations.help.timecommand, {
            { name=Config.Translations.help.timehname, help=Config.Translations.help.timeh },
            { name=Config.Translations.help.timemname, help=Config.Translations.help.timem }
        })
    end
end)

RegisterNetEvent('esx-weathersync:client:SyncTime', function(base, offset, freeze)
    freezeTime = freeze
    timeOffset = offset
    baseTime = base
end)

CreateThread(function()
    while true do
        if not disable then
            if lastWeather ~= CurrentWeather then
                lastWeather = CurrentWeather
                SetWeatherTypeOverTime(CurrentWeather, 15.0)
                Wait(15000)
            end
            Wait(100) -- Wait 0 seconds to prevent crashing.
            SetArtificialLightsState(blackout)
            SetArtificialLightsStateAffectsVehicles(blackoutVehicle)
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            SetWeatherTypePersist(lastWeather)
            SetWeatherTypeNow(lastWeather)
            SetWeatherTypeNowPersist(lastWeather)
            if lastWeather == 'XMAS' then
                SetForceVehicleTrails(true)
                SetForcePedFootstepsTracks(true)
            else
                SetForceVehicleTrails(false)
                SetForcePedFootstepsTracks(false)
            end
            if lastWeather == 'RAIN' then
                SetRainLevel(0.3)
            elseif lastWeather == 'THUNDER' then
                SetRainLevel(0.5)
            else
                SetRainLevel(0.0)
            end
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    local hour
    local minute = 0
    local second = 0        --Add seconds for shadow smoothness
    while true do
        if not disable then
            Wait(0)
            local newBaseTime = baseTime
            if GetGameTimer() - 22  > timer then    --Generate seconds in client side to avoid communiation
                second = second + 1                 --Minutes are sent from the server every 2 seconds to keep sync
                timer = GetGameTimer()
            end
            if freezeTime then
                timeOffset = timeOffset + baseTime - newBaseTime
                second = 0
            end
            baseTime = newBaseTime
            hour = math.floor(((baseTime+timeOffset)/60)%24)
            if minute ~= math.floor((baseTime+timeOffset)%60) then  --Reset seconds to 0 when new minute
                minute = math.floor((baseTime+timeOffset)%60)
                second = 0
            end
            NetworkOverrideClockTime(hour, minute, second)          --Send hour included seconds to network clock time
        else
            Wait(1000)
        end
    end
end)
