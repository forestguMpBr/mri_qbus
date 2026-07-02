-- ─────────────────────────────────────────────────────────────────────────────
--  mri_qbus | client/main.lua  (optimized)
-- ─────────────────────────────────────────────────────────────────────────────

local activeRoute      = nil
local missionVehicle   = nil
local rentExpiry       = nil
local currentPassenger = nil
local onBus            = false
local condition        = 100
local routeStartTime   = nil
local passengerGender  = 'male'
local isNUIOpen        = false
local currentStopPos   = nil
local currentStopIdx   = 0
local totalStops       = 0

-- ─── Cache dos coords dos terminais (evita criar vector3 por frame) ──────────

local standCoords = {}
CreateThread(function()
    for i, stand in ipairs(Config.BusStands) do
        standCoords[i] = vector3(stand.coords.x, stand.coords.y, stand.coords.z)

        local blip = AddBlipForCoord(stand.coords.x, stand.coords.y, stand.coords.z)
        SetBlipSprite(blip, stand.blip.sprite)
        SetBlipColour(blip, stand.blip.color)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(stand.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

-- ─── Thread principal: sleep adaptativo por distância ────────────────────────
-- Idle (sem veículo e sem rota): verifica distância a cada 2s
-- Perto de terminal (< 60m): ativa render loop Wait(0)
-- Em rota: ativa render loop Wait(0)

local renderActive = false  -- controla se o render loop está rodando

local function StartRenderLoop()
    if renderActive then return end
    renderActive = true

    CreateThread(function()
        local textUIShown = false

        while renderActive do
            Wait(0)

            local ped    = PlayerPedId()
            local plyPos = GetEntityCoords(ped)

            -- Marker da parada atual
            if activeRoute and currentStopPos then
                DrawMarker(1,
                    currentStopPos.x, currentStopPos.y, currentStopPos.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    4.0, 4.0, 1.0,
                    0, 180, 255, 180,
                    false, false, 2, false, false, false, false)
            end

            -- Terminais: marker + textUI + tecla E
            local nearAny = false
            for i = 1, #standCoords do
                local sc   = standCoords[i]
                local dist = #(plyPos - sc)
                local stand = Config.BusStands[i]

                if dist < 30.0 then
                    DrawMarker(2,
                        sc.x, sc.y, sc.z,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.5, 0.5, 0.5,
                        255, 180, 0, 200,
                        false, false, 2, false, false, false, false)
                end

                if dist < 2.0 and not isNUIOpen then
                    nearAny = true
                    if not textUIShown then
                        lib.showTextUI('[E] Terminal de Ônibus', { position = 'right-center' })
                        textUIShown = true
                    end
                    if IsControlJustReleased(0, 38) then
                        OpenBusUI()
                    end
                end
            end

            if not nearAny and textUIShown then
                lib.hideTextUI()
                textUIShown = false
            end

            -- F6 cancelar rota
            if activeRoute and IsDisabledControlJustReleased(0, 322) then
                CancelRoute()
            end
        end
    end)
end

local function StopRenderLoop()
    renderActive = false
end

-- ─── Thread de proximidade (dorme bastante, só acorda o render quando precisa)

CreateThread(function()
    while true do
        local ped    = PlayerPedId()
        local plyPos = GetEntityCoords(ped)

        local nearTerminal = false
        for i = 1, #standCoords do
            if #(plyPos - standCoords[i]) < 60.0 then
                nearTerminal = true
                break
            end
        end

        local needsRender = nearTerminal or (activeRoute ~= nil)

        if needsRender and not renderActive then
            StartRenderLoop()
        elseif not needsRender and renderActive then
            StopRenderLoop()
        end

        -- Dorme mais quando longe, menos quando perto
        Wait(nearTerminal and 1000 or 2000)
    end
end)

-- ─── Cancelar Rota ───────────────────────────────────────────────────────────

function CancelRoute()
    local confirmed = lib.alertDialog({
        header   = 'Cancelar Rota',
        content  = 'Tem certeza que deseja cancelar a rota atual?\nVocê não receberá pagamento pela rota incompleta.',
        centered = true,
        cancel   = true,
    })
    if confirmed == 'confirm' then
        activeRoute      = nil
        currentStopPos   = nil
        currentStopIdx   = 0
        totalStops       = 0
        if currentPassenger and DoesEntityExist(currentPassenger) then
            DeleteEntity(currentPassenger)
            currentPassenger = nil
        end
        onBus = false
        ClearGpsPlayerWaypoint()
        lib.notify({ title = 'Rota Cancelada', description = 'Rota cancelada. Seu ônibus continua disponível.', type = 'error' })
    end
end

-- ─── NUI ─────────────────────────────────────────────────────────────────────

function OpenBusUI()
    isNUIOpen = true
    SetNuiFocus(true, true)

    local playerData = lib.callback.await('mri_Qbus:getPlayerData', false)
    local routes     = lib.callback.await('mri_Qbus:getRoutes',     false)
    local ranking    = lib.callback.await('mri_Qbus:getRanking',    false, 'xp')

    SendNUIMessage({
        action      = 'openUI',
        playerData  = playerData,
        routes      = routes,
        ranking     = ranking,
        rentOptions = Config.BusRentOptions,
        buyOptions  = Config.BusBuyOptions,
        levels      = Config.Levels,
        hasRoute    = activeRoute ~= nil,
    })
end

RegisterNUICallback('closeUI', function(_, cb)
    isNUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('cancelRoute', function(_, cb)
    if not activeRoute then cb({ success = false, msg = 'Nenhuma rota ativa.' }) return end
    activeRoute      = nil
    currentStopPos   = nil
    currentStopIdx   = 0
    totalStops       = 0
    if currentPassenger and DoesEntityExist(currentPassenger) then
        DeleteEntity(currentPassenger)
        currentPassenger = nil
    end
    onBus = false
    ClearGpsPlayerWaypoint()
    cb({ success = true })
end)

RegisterNUICallback('storeVehicle', function(_, cb)
    if activeRoute then
        cb({ success = false, msg = 'Finalize ou cancele a rota antes de guardar.' })
        return
    end
    if not missionVehicle or not DoesEntityExist(missionVehicle) then
        cb({ success = false, msg = 'Nenhum ônibus para guardar.' })
        return
    end
    if currentPassenger and DoesEntityExist(currentPassenger) then
        DeleteEntity(currentPassenger)
        currentPassenger = nil
    end
    local ped = PlayerPedId()
    if IsPedInVehicle(ped, missionVehicle, false) then
        TaskLeaveVehicle(ped, missionVehicle, 0)
        Wait(1500)
    end
    DeleteEntity(missionVehicle)
    missionVehicle = nil
    rentExpiry     = nil
    onBus          = false
    cb({ success = true })
end)

RegisterNUICallback('acceptRoute', function(data, cb)
    if activeRoute then cb({ success = false, msg = 'Você já está em uma rota!' }) return end
    if not missionVehicle or not DoesEntityExist(missionVehicle) then
        cb({ success = false, msg = 'Você precisa de um ônibus para iniciar uma rota!' })
        return
    end
    local ok, route = lib.callback.await('mri_Qbus:acceptRoute', false, data.routeId)
    if not ok then cb({ success = false, msg = 'Rota não disponível. Tente outra.' }) return end

    activeRoute    = route
    condition      = 100
    routeStartTime = GetGameTimer()
    StartRoute(route)
    cb({ success = true })
end)

RegisterNUICallback('rentBus', function(data, cb)
    local ok, result = lib.callback.await('mri_Qbus:rentBus', false, data.optionId)
    if not ok then cb({ success = false, msg = result }) return end
    SpawnMissionVehicle(Config.RentVehicleModel)
    rentExpiry = GetGameTimer() + (result * 60 * 1000)
    cb({ success = true })
end)

RegisterNUICallback('buyBus', function(data, cb)
    local ok, result = lib.callback.await('mri_Qbus:buyBus', false, data.model)
    if not ok then cb({ success = false, msg = result }) return end
    SpawnMissionVehicle(data.model)
    cb({ success = true })
end)

RegisterNUICallback('getRanking', function(data, cb)
    cb({ ranking = lib.callback.await('mri_Qbus:getRanking', false, data.category) })
end)

-- ─── Spawn do Veículo ─────────────────────────────────────────────────────────

function SpawnMissionVehicle(model)
    if missionVehicle and DoesEntityExist(missionVehicle) then
        DeleteEntity(missionVehicle)
    end

    local plyPos    = GetEntityCoords(PlayerPedId())
    local bestStand = Config.BusStands[1]
    local bestDist  = math.huge
    for i, sc in ipairs(standCoords) do
        local d = #(plyPos - sc)
        if d < bestDist then bestDist = d; bestStand = Config.BusStands[i] end
    end

    local sp   = bestStand.spawnPoint
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(100) end

    -- Tenta spawnar até 5 vezes (CreateVehicle pode retornar 0 se área congestionada)
    local attempts = 0
    repeat
        attempts = attempts + 1
        missionVehicle = CreateVehicle(hash, sp.coords.x, sp.coords.y, sp.coords.z, sp.heading, true, false)
        if not DoesEntityExist(missionVehicle) or missionVehicle == 0 then
            missionVehicle = nil
            Wait(500)
        end
    until missionVehicle or attempts >= 5

    SetModelAsNoLongerNeeded(hash)

    if not missionVehicle then
        lib.notify({ title = 'Erro', description = 'Não foi possível spawnar o ônibus. Tente novamente.', type = 'error' })
        return
    end

    SetVehicleOnGroundProperly(missionVehicle)
    SetVehicleNeedsToBeHotwired(missionVehicle, false)
    SetVehRadioStation(missionVehicle, 'OFF')

    TaskWarpPedIntoVehicle(PlayerPedId(), missionVehicle, -1)
    Wait(600)
    SetVehicleEngineOn(missionVehicle, true, false, true)

    TriggerServerEvent('mri_Qbus:giveVehicleKey', GetVehicleNumberPlateText(missionVehicle))
    lib.notify({ title = 'Ônibus', description = 'Você está no ônibus! Boa viagem.', type = 'success' })
end

-- ─── Aluguel expirado (intervalo longo, sem custo) ───────────────────────────

CreateThread(function()
    while true do
        Wait(30000)
        if rentExpiry and GetGameTimer() > rentExpiry then
            lib.notify({ title = 'Aluguel Expirado', description = 'Seu ônibus alugado foi recolhido.', type = 'error' })
            if missionVehicle and DoesEntityExist(missionVehicle) then DeleteEntity(missionVehicle) end
            missionVehicle = nil
            rentExpiry     = nil
            if activeRoute then
                activeRoute    = nil
                currentStopPos = nil
                lib.notify({ title = 'Rota Cancelada', description = 'Rota cancelada pois o veículo foi recolhido.', type = 'error' })
            end
        end
    end
end)

-- ─── Gerenciamento de Rota ────────────────────────────────────────────────────

function StartRoute(route)
    lib.notify({ title = 'Linha ' .. route.label, description = 'Dirija até a primeira parada!', type = 'info' })

    local stops    = route.resolvedStops
    totalStops     = #stops
    currentStopIdx = 1
    currentStopPos = vector3(stops[1].x, stops[1].y, stops[1].z)
    SetNewWaypoint(stops[1].x, stops[1].y)

    -- Pré-cacheia os vector3 de cada parada
    local stopVecs = {}
    for i, s in ipairs(stops) do
        stopVecs[i] = vector3(s.x, s.y, s.z)
    end

    CreateThread(function()
        local stopIdx    = 1
        local textShown  = false

        while activeRoute and stopIdx <= #stops do
            local stopPos = stopVecs[stopIdx]
            local dist    = #(GetEntityCoords(PlayerPedId()) - stopPos)

            if dist < 8.0 then
                if missionVehicle and DoesEntityExist(missionVehicle) and IsVehicleStopped(missionVehicle) then
                    if textShown then lib.hideTextUI(); textShown = false end

                    if onBus then
                        PassengerGetOff(stopPos, stopIdx, #stops, route)
                    else
                        PassengerGetOn(stopPos)
                    end

                    stopIdx        = stopIdx + 1
                    currentStopIdx = stopIdx

                    if stopIdx <= #stops then
                        currentStopPos = stopVecs[stopIdx]
                        SetNewWaypoint(stops[stopIdx].x, stops[stopIdx].y)
                        lib.notify({ title = 'Próxima Parada', description = ('Parada %d/%d'):format(stopIdx, #stops), type = 'info' })
                    else
                        currentStopPos = nil
                    end
                else
                    if not textShown then
                        lib.showTextUI('Pare o ônibus para embarcar/desembarcar', { position = 'top-center' })
                        textShown = true
                    end
                end
            else
                if textShown then lib.hideTextUI(); textShown = false end
            end

            Wait(500)
        end

        if activeRoute then CompleteRoute(route) end
    end)
end

-- ─── Embarque / Desembarque ───────────────────────────────────────────────────

function PassengerGetOn(coords)
    local modelName = Config.PassengerModels[math.random(#Config.PassengerModels)]
    passengerGender = modelName:find('_f_') and 'female' or 'male'
    local hash = GetHashKey(modelName)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(100) end

    -- Encontra assento disponível
    local targetSeat = -2
    for seat = 0, GetVehicleMaxNumberOfPassengers(missionVehicle) do
        if IsVehicleSeatFree(missionVehicle, seat) then
            targetSeat = seat
            break
        end
    end

    if targetSeat == -2 then
        SetModelAsNoLongerNeeded(hash)
        lib.notify({ title = 'Ônibus Lotado', description = 'Não há assentos disponíveis.', type = 'error' })
        return
    end

    -- Spawna o ped na calçada perto da porta
    currentPassenger = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, 0.0, false, false)
    SetEntityInvincible(currentPassenger, true)
    SetBlockingOfNonTemporaryEvents(currentPassenger, true)
    SetPedCanBeDraggedOut(currentPassenger, false)
    SetModelAsNoLongerNeeded(hash)

    -- Animação de entrada real (veículo NÃO está congelado)
    TaskEnterVehicle(currentPassenger, missionVehicle, 10000, targetSeat, 2.0, 1, 0)

    -- Aguarda entrar de fato (até 10s)
    local timeout = 20
    while not IsPedInVehicle(currentPassenger, missionVehicle, false) and timeout > 0 do
        timeout = timeout - 1
        Wait(500)
    end

    -- Se não entrou (bug de pathfinding), força via warp
    if not IsPedInVehicle(currentPassenger, missionVehicle, false) then
        ClearPedTasksImmediately(currentPassenger)
        TaskWarpPedIntoVehicle(currentPassenger, missionVehicle, targetSeat)
        Wait(300)
    end

    onBus = true
    lib.notify({ title = 'Passageiro', description = 'Passageiro embarcou! Dirija com cuidado.', type = 'success' })
end

function PassengerGetOff(coords, stopIdx, totalStopsCount, route)
    if currentPassenger and DoesEntityExist(currentPassenger) then
        -- Animação de saída real (veículo NÃO está congelado)
        TaskLeaveVehicle(currentPassenger, missionVehicle, 0)

        -- Aguarda sair do veículo (até 8s)
        local timeout = 16
        while IsPedInAnyVehicle(currentPassenger, false) and timeout > 0 do
            timeout = timeout - 1
            Wait(500)
        end

        -- Pequena animação pós-desembarque (anda alguns passos)
        TaskWanderStandard(currentPassenger, 5.0, 10)
        Wait(1500)

        SetEntityAsNoLongerNeeded(currentPassenger)
        DeleteEntity(currentPassenger)
        currentPassenger = nil
    end

    TriggerServerEvent('mri_Qbus:completeStop', {
        templateId = route.templateId,
        condition  = condition,
        stopIndex  = stopIdx,
        totalStops = totalStopsCount,
    })

    onBus     = false
    condition = math.min(100, condition + 5)
    lib.notify({ title = 'Passageiro Desembarcou', description = ('Parada %d/%d concluída!'):format(stopIdx, totalStopsCount), type = 'success' })
end

-- ─── Conclusão de Rota ────────────────────────────────────────────────────────

function CompleteRoute(route)
    TriggerServerEvent('mri_Qbus:completeRoute', {
        templateId = route.templateId,
        elapsed    = math.floor((GetGameTimer() - routeStartTime) / 1000),
        condition  = condition,
    })
    activeRoute    = nil
    currentStopPos = nil
    currentStopIdx = 0
    totalStops     = 0
    ClearGpsPlayerWaypoint()
    lib.notify({ title = 'Rota Concluída!', description = route.label .. ' finalizada com sucesso!', type = 'success' })
end

-- ─── Penalidades de Condução ──────────────────────────────────────────────────
-- Só roda quando há rota ativa; dorme 2s quando idle

CreateThread(function()
    local lastSpeed      = 0.0
    local impactCooldown = 0
    local lastCondition  = -1  -- evita SendNUIMessage desnecessário

    while true do
        if not activeRoute or not missionVehicle or not DoesEntityExist(missionVehicle) then
            lastSpeed      = 0.0
            impactCooldown = 0
            Wait(2000)
        else
            Wait(500)
            local speedKmh = GetEntitySpeed(missionVehicle) * 3.6

            if speedKmh > Config.MaxSafeSpeed then
                condition = math.max(0, condition - Config.SpeedConditionLoss * (speedKmh - Config.MaxSafeSpeed))
                if onBus and math.random(100) <= 3 then
                    local lst = Config.Infractions.speed[passengerGender]
                    if lst then lib.notify({ title = 'Passageiro Irritado', description = lst[math.random(#lst)].text, type = 'error' }) end
                end
            end

            local drop = lastSpeed - speedKmh
            if impactCooldown <= 0 and lastSpeed > 15.0 and drop > 20.0 then
                condition = math.max(0, condition - Config.ImpactConditionLoss)
                if onBus and math.random(100) <= 60 then
                    local lst = Config.Infractions.impact[passengerGender]
                    if lst then lib.notify({ title = 'Passageiro Irritado', description = lst[math.random(#lst)].text, type = 'error' }) end
                end
                impactCooldown = 6
            end

            if impactCooldown > 0 then impactCooldown = impactCooldown - 1 end
            lastSpeed = speedKmh

            -- Só envia NUI se o valor mudou
            local condInt = math.floor(condition)
            if condInt ~= lastCondition then
                SendNUIMessage({ action = 'updateCondition', condition = condInt })
                lastCondition = condInt
            end
        end
    end
end)

-- ─── Resultados vindos do servidor ───────────────────────────────────────────

RegisterNetEvent('mri_Qbus:stopResult', function(data)
    SendNUIMessage({ action = 'stopResult', data = data })
    lib.notify({
        title       = ('Parada %d/%d'):format(data.stopIndex, data.totalStops),
        description = ('+ R$%d  | + %d XP  | Satisfação: %d%%'):format(data.pay, data.xp, data.condition),
        type        = 'success',
    })
end)

RegisterNetEvent('mri_Qbus:routeResult', function(data)
    SendNUIMessage({ action = 'routeResult', data = data })
    if data.leveledUp then
        lib.notify({ title = '🚌 Level UP! → ' .. data.newLevelLabel, description = ('Você subiu para o nível %d!'):format(data.newLevel), type = 'success', duration = 6000 })
    end
    if data.bonus > 0 then
        lib.notify({ title = '⚡ Bônus de Velocidade!', description = ('+ R$%d  | + %d XP'):format(data.bonus, data.bonusXP), type = 'success' })
    end
end)

-- ─── Limpeza ─────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    if currentPassenger and DoesEntityExist(currentPassenger) then DeleteEntity(currentPassenger) end
    if missionVehicle   and DoesEntityExist(missionVehicle)   then DeleteEntity(missionVehicle)  end
end)


-- ─── Comando para capturar coordenadas do prop_busstop_02 mais próximo ────────
-- Use: /busstopcoord no chat — copia a coord no F8 e no clipboard

RegisterCommand('busstopcoord', function()
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local hash   = GetHashKey('prop_busstop_02')

    local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 50.0, hash, false, false, false)

    if DoesEntityExist(obj) then
        local p = GetEntityCoords(obj)
        local h = GetEntityHeading(obj)
        local line = string.format('vector4(%.4f, %.4f, %.4f, %.4f),', p.x, p.y, p.z, h)
        print('[mri_qbus] prop_busstop_02 encontrado: ' .. line)
        lib.setClipboard(line)
        lib.notify({
            title       = '🚌 Bus Stop Coord',
            description = line .. '\n(copiado para o clipboard!)',
            type        = 'success',
            duration    = 8000,
        })
    else
        lib.notify({
            title       = '🚌 Bus Stop Coord',
            description = 'Nenhum prop_busstop_02 encontrado em até 50m.',
            type        = 'error',
            duration    = 4000,
        })
    end
end, false)
