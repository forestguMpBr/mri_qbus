-- ─────────────────────────────────────────────────────────────────────────────
--  mri_qbus | server/main.lua
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── DB Helpers ───────────────────────────────────────────────────────────────

local function dbGetPlayer(citizenid)
    return MySQL.single.await('SELECT * FROM mri_qbus_players WHERE citizenid = ?', { citizenid })
end

local function dbCreatePlayer(citizenid)
    MySQL.insert.await('INSERT INTO mri_qbus_players (citizenid) VALUES (?)', { citizenid })
    return { citizenid = citizenid, xp = 0, level = 1, total_routes = 0, total_stops = 0, total_earned = 0, history = '[]', owned_buses = '[]' }
end

local function loadPlayer(citizenid)
    local data = dbGetPlayer(citizenid)
    if not data then data = dbCreatePlayer(citizenid) end
    data.history    = json.decode(data.history    or '[]')
    data.owned_buses = json.decode(data.owned_buses or '[]')
    return data
end

local function savePlayer(data)
    MySQL.update.await(
        'UPDATE mri_qbus_players SET xp=?, level=?, total_routes=?, total_stops=?, total_earned=?, history=?, owned_buses=? WHERE citizenid=?',
        { data.xp, data.level, data.total_routes, data.total_stops, data.total_earned,
          json.encode(data.history), json.encode(data.owned_buses), data.citizenid }
    )
end

-- ─── Callback: Dados do Jogador ───────────────────────────────────────────────

lib.callback.register('mri_Qbus:getPlayerData', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local data  = loadPlayer(player.PlayerData.citizenid)
    local level = GetPlayerLevel(data.xp)
    data.level         = level
    data.xpProgress    = GetXPProgress(data.xp)
    data.xpToNextLevel = GetXPToNextLevel(data.xp)
    data.levelData     = Config.Levels[level]

    local rank = MySQL.scalar.await('SELECT COUNT(*) FROM mri_qbus_players WHERE xp > ?', { data.xp }) + 1
    data.rank    = rank
    data.rankBuff = Config.TopRankingBuffs and Config.TopRankingBuffs[rank] or nil

    return data
end)

-- ─── Geração de Rotas Ativas ──────────────────────────────────────────────────

local ActiveRoutes = {}

local function GenerateRoute()
    local template = Config.Routes[math.random(#Config.Routes)]
    local id = tostring(math.random(100000, 999999))

    ActiveRoutes[id] = {
        id       = id,
        templateId = template.id,
        label    = template.label,
        zone     = template.zone,
        stops    = template.stops,
        basePay  = template.basePay,
        baseXP   = template.baseXP,
        minLevel = template.minLevel,
        distance = template.distance,
    }
end

CreateThread(function()
    local maxRoutes = Config.MaxActiveRoutes or 10
    for i = 1, maxRoutes do GenerateRoute() end

    while true do
        Wait((Config.RouteGenerateInterval or 45) * 1000)

        local count, keys = 0, {}
        for k in pairs(ActiveRoutes) do
            count = count + 1
            table.insert(keys, k)
        end

        if count >= maxRoutes then
            ActiveRoutes[keys[math.random(#keys)]] = nil
        end

        GenerateRoute()
    end
end)

-- ─── Callback: Listar Rotas Disponíveis ───────────────────────────────────────

lib.callback.register('mri_Qbus:getRoutes', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    local data  = loadPlayer(player.PlayerData.citizenid)
    local level = GetPlayerLevel(data.xp)

    local available = {}
    for _, route in pairs(ActiveRoutes) do
        if level >= route.minLevel then
            table.insert(available, route)
        end
    end
    return available
end)

-- ─── Callback: Aceitar Rota ───────────────────────────────────────────────────

lib.callback.register('mri_Qbus:acceptRoute', function(source, routeId)
    if ActiveRoutes[routeId] then
        local route = ActiveRoutes[routeId]
        ActiveRoutes[routeId] = nil

        -- Resolve waypoints reais
        local resolvedStops = {}
        for _, idx in ipairs(route.stops) do
            local wp = Config.Stops[idx]
            if wp then table.insert(resolvedStops, { x = wp.x, y = wp.y, z = wp.z, w = wp.w }) end
        end
        route.resolvedStops = resolvedStops

        return true, route
    end
    return false, nil
end)

-- ─── Callback: Alugar Ônibus ─────────────────────────────────────────────────

lib.callback.register('mri_Qbus:rentBus', function(source, id)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false, 'Jogador não encontrado' end

    local option = nil
    for _, opt in ipairs(Config.BusRentOptions) do
        if opt.id == id then option = opt break end
    end
    if not option then return false, 'Opção inválida' end

    local price = option.price
    local cash  = player.PlayerData.money['cash']
    local bank  = player.PlayerData.money['bank']

    if cash >= price then
        player.Functions.RemoveMoney('cash', price, 'mri_qbus-rent')
        return true, option.duration
    elseif bank >= price then
        player.Functions.RemoveMoney('bank', price, 'mri_qbus-rent')
        return true, option.duration
    end
    return false, 'Dinheiro insuficiente'
end)

-- ─── Callback: Comprar Ônibus ─────────────────────────────────────────────────

lib.callback.register('mri_Qbus:buyBus', function(source, model)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false, 'Jogador não encontrado' end

    local option = nil
    for _, opt in ipairs(Config.BusBuyOptions) do
        if opt.model == model then option = opt break end
    end
    if not option then return false, 'Opção inválida' end

    local data = loadPlayer(player.PlayerData.citizenid)
    for _, v in ipairs(data.owned_buses) do
        if v == model then return false, 'Você já possui este veículo' end
    end

    local price = option.price
    local cash  = player.PlayerData.money['cash']
    local bank  = player.PlayerData.money['bank']

    if cash >= price then
        player.Functions.RemoveMoney('cash', price, 'mri_qbus-buy')
    elseif bank >= price then
        player.Functions.RemoveMoney('bank', price, 'mri_qbus-buy')
    else
        return false, 'Dinheiro insuficiente'
    end

    table.insert(data.owned_buses, model)
    savePlayer(data)
    return true
end)

-- ─── Callback: Ranking ───────────────────────────────────────────────────────

lib.callback.register('mri_Qbus:getRanking', function(source, category)
    local orderCol = 'xp'
    if category == 'level'   then orderCol = 'level'
    elseif category == 'routes' then orderCol = 'total_routes'
    end

    local query = string.format(
        'SELECT citizenid, xp, level, total_routes, total_stops FROM mri_qbus_players ORDER BY %s DESC LIMIT 50',
        orderCol
    )
    local playersData = MySQL.query.await(query)
    local ranking = {}
    if not playersData then return ranking end

    for _, v in ipairs(playersData) do
        local name  = 'Desconhecido'
        local pData = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?', { v.citizenid })

        if pData and pData.charinfo then
            local charinfo = pData.charinfo
            if type(charinfo) == 'string' then
                local ok, res = pcall(json.decode, charinfo)
                if ok then charinfo = res else charinfo = nil end
            end
            if type(charinfo) == 'table' and charinfo.firstname and charinfo.lastname then
                name = charinfo.firstname .. ' ' .. charinfo.lastname
            end
        end

        table.insert(ranking, {
            citizenid    = v.citizenid,
            name         = name,
            xp           = v.xp,
            level        = v.level,
            total_routes = v.total_routes,
            total_stops  = v.total_stops,
        })
    end
    return ranking
end)

-- ─── Evento: Completar Parada ─────────────────────────────────────────────────
-- Disparado pelo cliente a cada parada concluída (passageiro embarca/desembarca).

RegisterNetEvent('mri_Qbus:completeStop', function(payload)
    local src    = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local templateId = payload.templateId
    local condition  = math.floor(math.max(0, math.min(100, payload.condition)))
    local stopIndex  = payload.stopIndex   -- índice atual dentro da rota
    local totalStops = payload.totalStops

    -- Localiza template da rota
    local template = nil
    for _, r in ipairs(Config.Routes) do
        if r.id == templateId then template = r break end
    end
    if not template then return end

    local data  = loadPlayer(player.PlayerData.citizenid)
    local level = GetPlayerLevel(data.xp)
    local mult  = Config.Levels[level].multiplier

    -- Pagamento por parada = basePay dividido pelo nº de paradas, escalado pela condição e multiplicador
    local payPerStop = math.floor((template.basePay / totalStops) * mult * (condition / 100))
    local xpPerStop  = math.floor((template.baseXP  / totalStops))

    if condition >= 90 then xpPerStop = math.floor(xpPerStop * 1.10) end

    local rank     = MySQL.scalar.await('SELECT COUNT(*) FROM mri_qbus_players WHERE xp > ?', { data.xp }) + 1
    local rankBuff = (Config.TopRankingBuffs and Config.TopRankingBuffs[rank]) or 1.0

    local totalPay = math.floor(payPerStop * rankBuff)

    data.xp          = data.xp + xpPerStop
    data.total_stops = data.total_stops + 1
    data.total_earned = data.total_earned + totalPay
    data.level        = GetPlayerLevel(data.xp)

    savePlayer(data)
    player.Functions.AddMoney('cash', totalPay, 'bus-stop')

    TriggerClientEvent('mri_Qbus:stopResult', src, {
        pay       = totalPay,
        xp        = xpPerStop,
        condition = condition,
        stopIndex = stopIndex,
        totalStops = totalStops,
    })
end)

-- ─── Evento: Completar Rota Inteira ──────────────────────────────────────────

RegisterNetEvent('mri_Qbus:completeRoute', function(payload)
    local src    = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local templateId = payload.templateId
    local elapsed    = payload.elapsed
    local condition  = math.floor(math.max(0, math.min(100, payload.condition)))

    local template = nil
    for _, r in ipairs(Config.Routes) do
        if r.id == templateId then template = r break end
    end
    if not template then return end

    local data  = loadPlayer(player.PlayerData.citizenid)
    local level = GetPlayerLevel(data.xp)
    local mult  = Config.Levels[level].multiplier

    local rank     = MySQL.scalar.await('SELECT COUNT(*) FROM mri_qbus_players WHERE xp > ?', { data.xp }) + 1
    local rankBuff = (Config.TopRankingBuffs and Config.TopRankingBuffs[rank]) or 1.0

    -- Bônus de conclusão de rota completa
    local bonus = 0
    if elapsed <= (Config.FastRouteMinutes * 60) then
        bonus = math.floor(template.basePay * mult * Config.TimeBonusPercent * rankBuff)
    end

    local bonusXP = 0
    if elapsed <= (Config.FastRouteMinutes * 60) then bonusXP = math.floor(template.baseXP * 0.25) end
    if condition >= 90 then bonusXP = bonusXP + math.floor(template.baseXP * 0.10) end

    local oldLevel = level
    data.xp           = data.xp + bonusXP
    data.total_routes = data.total_routes + 1
    data.total_earned = data.total_earned + bonus
    data.level        = GetPlayerLevel(data.xp)

    -- Histórico
    local entry = {
        route     = template.label,
        bonus     = bonus,
        bonusXP   = bonusXP,
        condition = condition,
        date      = os.date('%d/%m %H:%M'),
    }
    table.insert(data.history, 1, entry)
    if #data.history > 20 then table.remove(data.history) end

    savePlayer(data)
    if bonus > 0 then player.Functions.AddMoney('cash', bonus, 'bus-route-bonus') end

    TriggerClientEvent('mri_Qbus:routeResult', src, {
        bonus     = bonus,
        bonusXP   = bonusXP,
        condition = condition,
        leveledUp = data.level > oldLevel,
        newLevel  = data.level,
        newLevelLabel = Config.Levels[data.level] and Config.Levels[data.level].label or '',
        totalXP   = data.xp,
    })
end)

-- ─── Criação da Tabela ────────────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mri_qbus_players` (
            `citizenid`     VARCHAR(50)  NOT NULL,
            `xp`            INT          NOT NULL DEFAULT 0,
            `level`         INT          NOT NULL DEFAULT 1,
            `total_routes`  INT          NOT NULL DEFAULT 0,
            `total_stops`   INT          NOT NULL DEFAULT 0,
            `total_earned`  BIGINT       NOT NULL DEFAULT 0,
            `owned_buses`   LONGTEXT              DEFAULT '[]',
            `history`       LONGTEXT,
            `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)


-- ─── Dar chave do veículo via mri_Qcarkeys ───────────────────────────────────
RegisterNetEvent('mri_Qbus:giveVehicleKey', function(plate)
    local src = source
    exports.mri_Qcarkeys:GiveTempKeys(src, plate)
end)
