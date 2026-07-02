Config = {}

Config.Debug = false

Config.ResourceName = 'mri_qbus'

-- ─── Intervalo de Geração de Rotas ───────────────────────────────────────────
Config.RouteGenerateInterval = 45   -- segundos entre novas rotas disponíveis
Config.MaxActiveRoutes        = 10  -- limite de rotas simultâneas no servidor

-- ─── Veículo Padrão de Aluguel ───────────────────────────────────────────────
Config.RentVehicleModel = 'bus'

-- ─── Opções de Aluguel ───────────────────────────────────────────────────────
Config.BusRentOptions = {
    { id = 'rent_30',  label = 'Aluguel Rápido',  price = 300,  duration = 30,  image = 'https://docs.fivem.net/vehicles/bus.webp',  desc = 'Aluguel por 30 Minutos' },
    { id = 'rent_60',  label = 'Aluguel Padrão',  price = 500,  duration = 60,  image = 'https://docs.fivem.net/vehicles/bus.webp',  desc = 'Aluguel por 1 Hora' },
    { id = 'rent_120', label = 'Aluguel Diário',  price = 900,  duration = 120, image = 'https://docs.fivem.net/vehicles/bus.webp',  desc = 'Aluguel por 2 Horas' },
}

-- ─── Ônibus Disponíveis para Compra ──────────────────────────────────────────
Config.BusBuyOptions = {
    { model = 'bus',     label = 'Ônibus Municipal',      price = 8000,  image = 'https://docs.fivem.net/vehicles/bus.webp',     desc = 'Ônibus padrão de Los Santos' },
    { model = 'coach',   label = 'Ônibus Executivo',      price = 18000, image = 'https://docs.fivem.net/vehicles/coach.webp',   desc = 'Ônibus de longa distância' },
    { model = 'airbus',  label = 'Ônibus Aeroporto',      price = 25000, image = 'https://docs.fivem.net/vehicles/airbus.webp',  desc = 'Ônibus de pista para LSIA' },
}

-- ─── Parâmetros de Penalidade / Corrida ──────────────────────────────────────
Config.MaxSafeSpeed        = 80      -- km/h máximo sem penalidade de satisfação
Config.SpeedConditionLoss  = 0.003   -- perda de satisfação por tick acima do limite
Config.ImpactConditionLoss = 1.5     -- perda de satisfação em colisões (pontos diretos)
Config.TimeBonusPercent    = 0.20    -- bônus de pagamento de 20% por rota completa rápida
Config.FastRouteMinutes    = 20      -- minutos máximos para ganhar bônus de tempo

-- ─── Níveis e Títulos ────────────────────────────────────────────────────────
Config.Levels = {
    [1]  = { xp = 0,      label = "Aprendiz",             multiplier = 1.00, color = "#9ca3af" },
    [2]  = { xp = 300,    label = "Motorista Iniciante",  multiplier = 1.10, color = "#60a5fa" },
    [3]  = { xp = 800,    label = "Motorista Urbano",     multiplier = 1.25, color = "#34d399" },
    [4]  = { xp = 1800,   label = "Condutor",             multiplier = 1.40, color = "#a78bfa" },
    [5]  = { xp = 3500,   label = "Condutor Noturno",     multiplier = 1.60, color = "#f472b6" },
    [6]  = { xp = 6000,   label = "Condutor Experiente",  multiplier = 1.85, color = "#fb923c" },
    [7]  = { xp = 10000,  label = "Chefe de Linha",       multiplier = 2.10, color = "#fbbf24" },
    [8]  = { xp = 15000,  label = "Mestre do Volante",    multiplier = 2.40, color = "#f87171" },
    [9]  = { xp = 22000,  label = "Piloto de Frota",      multiplier = 2.80, color = "#c084fc" },
    [10] = { xp = 32000,  label = "Rei das Estradas",     multiplier = 3.50, color = "#f59e0b" },
}

-- ─── Bônus de Ranking ────────────────────────────────────────────────────────
Config.TopRankingBuffs = {
    [1] = 1.5,
    [2] = 1.3,
    [3] = 1.1,
}

-- ─── Pontos de Parada (Waypoints) ────────────────────────────────────────────
Config.Stops = {
    [1] = vector4(303.53, -766.33, 29.31, 247.1),
    [2] = vector4(264.42, -1213.14, 29.4, 183.4),
    [3] = vector4(25.38, -1354.62, 29.34, 178.19),
    [4] = vector4(-491.41, -1294.74, 27.23, 75.57), 
    [5] = vector4(-523.75, -1025.82, 22.84, 83.65),
    [6] = vector4(-529.46, -718.97, 33.08, 137.54),
    [7] = vector4(-504.14, -671.27, 33.09, 3.76),
    [8] = vector4(-119.96, -313.5, 39.21, 63.21),
    [9] = vector4(55.98, -231.11, 50.45, 67.66), 
    [10] = vector4(404.53, -304.59, 51.42, 338.33),
    [11] = vector4(244.79, -582.04, 43.22, 244.21),
    [12] = vector4(221.93, -855.83, 30.2, 335.89),
    [13] = vector4(399.54, -805.7, 29.29, 265.71),
    [14] = vector4(114.57, -780.98, 31.41, 147.72),
    [15] = vector4(-509.85, -645.99, 33.14, 185.41),
    [16] = vector4(-1011.6, -307.85, 37.87, 118.21),
    [17] = vector4(-1190.37, -337.7, 37.42, 249.9),
    [18] = vector4(-503.75, -671.06, 33.08, 352.21),
    [19] = vector4(83.43, -802.18, 31.52, 333.73),
    [20] = vector4(413.57, -777.89, 29.31, 80.37),
    [21] = vector4(303.53, -766.33, 29.31, 247.1),
    [22] = vector4(69.92, -1471.49, 29.29, 240.16),
    [23] = vector4(-226.08, -1793.37, 29.67, 214.71),
    [24] = vector4(-1071.45, -2566.53, 20.17, 239.76), -- LSIA 1
    [25] = vector4(-1027.37, -2736.93, 20.17, 337.3), -- LSIA 2
    [26] = vector4(-217.53, -1823.81, 30.0, 30.21),
    [27] = vector4(55.3, -1539.06, 29.32, 53.44),
    [28] = vector4(344.46, -741.74, 29.27, 74.19)
}

-- ─── Linhas de Ônibus (Rotas) ─────────────────────────────────────────────────
-- stops: lista de índices de Config.Stops que compõem a linha
Config.Routes = {
    -- ── Nível 1 ────────────────────────────────────────────────────────────────
    {
        id       = 1,
        label    = "Linha Centro",
        zone     = "centro",
        stops    = { 1, 7, 2, 5, 3, 4 },
        basePay  = 600,
        baseXP   = 80,
        minLevel = 1,
        distance = "Curta",
    },
    {
        id       = 2,
        label    = "Linha Vinewood Blvd",
        zone     = "centro",
        stops    = { 6, 8, 4, 3, 7 },
        basePay  = 700,
        baseXP   = 90,
        minLevel = 1,
        distance = "Curta",
    },
    -- ── Nível 2 ────────────────────────────────────────────────────────────────
    {
        id       = 3,
        label    = "Linha Sul / Vespucci",
        zone     = "sul",
        stops    = { 1, 5, 9, 10, 11, 12, 2 },
        basePay  = 900,
        baseXP   = 120,
        minLevel = 2,
        distance = "Média",
    },
    {
        id       = 4,
        label    = "Linha Strawberry",
        zone     = "sul",
        stops    = { 2, 20, 21, 22, 23, 1 },
        basePay  = 850,
        baseXP   = 110,
        minLevel = 2,
        distance = "Média",
    },
    -- ── Nível 3 ────────────────────────────────────────────────────────────────
    {
        id       = 5,
        label    = "Linha Vespucci Beach",
        zone     = "sul",
        stops    = { 9, 13, 14, 10, 11, 12 },
        basePay  = 1100,
        baseXP   = 140,
        minLevel = 3,
        distance = "Média",
    },
    {
        id       = 6,
        label    = "Linha La Mesa / Porto",
        zone     = "sul",
        stops    = { 23, 15, 16, 20, 22 },
        basePay  = 1200,
        baseXP   = 150,
        minLevel = 3,
        distance = "Média",
    },
    -- ── Nível 4 ────────────────────────────────────────────────────────────────
    {
        id       = 7,
        label    = "Linha Aeroporto",
        zone     = "aeroporto",
        stops    = { 2, 13, 17, 18, 19 },
        basePay  = 1400,
        baseXP   = 180,
        minLevel = 4,
        distance = "Longa",
    },
    {
        id       = 8,
        label    = "Linha LSIA Expresso",
        zone     = "aeroporto",
        stops    = { 1, 9, 14, 17, 18 },
        basePay  = 1600,
        baseXP   = 200,
        minLevel = 4,
        distance = "Longa",
    },
    -- ── Nível 5 ────────────────────────────────────────────────────────────────
    {
        id       = 9,
        label    = "Linha Rockford Hills",
        zone     = "luxo",
        stops    = { 4, 24, 25, 26, 27, 8 },
        basePay  = 2000,
        baseXP   = 250,
        minLevel = 5,
        distance = "Longa",
    },
    -- ── Nível 6 ────────────────────────────────────────────────────────────────
    {
        id       = 10,
        label    = "Linha Rockford VIP",
        zone     = "luxo",
        stops    = { 4, 24, 25, 26, 27, 6, 8 },
        basePay  = 3500,
        baseXP   = 420,
        minLevel = 6,
        distance = "Longa",
    },
    -- ── Nível 7 ────────────────────────────────────────────────────────────────
    {
        id       = 11,
        label    = "Linha Sandy Shores",
        zone     = "norte",
        stops    = { 1, 23, 31, 28, 32 },
        basePay  = 2500,
        baseXP   = 320,
        minLevel = 7,
        distance = "Muito Longa",
    },
    -- ── Nível 8 ────────────────────────────────────────────────────────────────
    {
        id       = 12,
        label    = "Linha Norte / Paleto",
        zone     = "norte",
        stops    = { 1, 31, 28, 29, 33, 30 },
        basePay  = 3200,
        baseXP   = 400,
        minLevel = 8,
        distance = "Muito Longa",
    },
    -- ── Nível 9 ────────────────────────────────────────────────────────────────
    {
        id       = 13,
        label    = "Linha Interestadual",
        zone     = "norte",
        stops    = { 1, 17, 31, 28, 29, 33, 30 },
        basePay  = 4000,
        baseXP   = 500,
        minLevel = 9,
        distance = "Extrema",
    },
    -- ── Nível 10 ───────────────────────────────────────────────────────────────
    {
        id       = 14,
        label    = "Linha Grand Tour",
        zone     = "norte",
        stops    = { 1, 24, 17, 23, 31, 28, 29, 33, 30 },
        basePay  = 5500,
        baseXP   = 700,
        minLevel = 10,
        distance = "Extrema",
    },
}

-- ─── Despachantes / Terminais ─────────────────────────────────────────────────
Config.BusStands = {
    {
        id         = 1,
        label      = "Terminal Rodoviário (Centro)",
        coords     = vector4(454.06, -622.56, 28.51, 251.65),
        ped        = "u_m_y_proldriver_01",
        blip       = { sprite = 513, color = 43, label = "Terminal de Ônibus" },
        spawnPoint = { coords = vector3(461.93, -628.29, 28.5), heading = 215.96, radius = 5.0 },
    },
    {
        id         = 2,
        label      = "Terminal Aeroporto (LSIA)",
        coords     = vector4(-1052.1, -2722.5, 13.7, 330.0),
        ped        = "a_m_m_business_01",
        blip       = { sprite = 513, color = 43, label = "Terminal de Ônibus" },
        spawnPoint = { coords = vector3(-1046.8, -2717.3, 13.7), heading = 330.0, radius = 5.0 },
    },
}

-- ─── Passageiros (modelos NPC) ────────────────────────────────────────────────
Config.PassengerModels = {
    "a_f_m_soucent_01", "a_f_m_soucent_02", "a_f_m_tourist_01",
    "a_f_y_business_01", "a_f_y_business_02", "a_f_y_eastsa_01",
    "a_m_m_business_01", "a_m_m_beach_01", "a_m_m_eastsa_01",
    "a_m_y_business_01", "a_m_y_business_02", "a_m_m_farmer_01",
    "s_m_m_paramedic_01", "ig_lamardavis", "ig_lazlow",
}

-- ─── Falas dos Passageiros ────────────────────────────────────────────────────
Config.Infractions = {
    speed = {
        male = {
            { text = "Ei, vai devagar com esse ônibus!", audio = nil },
            { text = "Essa é uma linha municipal, não o Dakar!", audio = nil },
        },
        female = {
            { text = "Para que essa pressa toda?!", audio = nil },
            { text = "Motorista irresponsável!", audio = nil },
        },
    },
    impact = {
        male = {
            { text = "Que batida foi essa?! Tá maluco?", audio = nil },
            { text = "Eu vou registrar uma reclamação!", audio = nil },
        },
        female = {
            { text = "Meu Deus, quase voei pro corredor!", audio = nil },
            { text = "Isso é um absurdo! Vou chamar o fiscal!", audio = nil },
        },
    },
}
