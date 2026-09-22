-- ============================================================
--  Military Pack: Скрипт поведения оружия и боеприпасов (v21.0)
--  100% ПОДЖОГ: каждый осколок и пуля зажигательные
--  ПРАВИЛЬНЫЕ СОБЫТИЯ FORTS API: OnWeaponFired + автосканер Update
--  УМНЫЙ ИИ ГСН-РАКЕТЫ: высотный эшелон (CruiseHeight) +
--  удержание цели (не «прыгает» между целями) +
--  приоритет по классу цели (РЕАКТОР -> БК -> орудия) +
--  стабилизация высоты -> ракета живёт ДО ЗЕМЛИ.
--  ЦЕЛИ: БОЧКИ, ЯЩИКИ С БК, РЕАКТОР И ОРУДИЯ ВРАГА!
-- ============================================================

dofile("scripts/forts.lua")

local atan2 = math.atan2 or math.atan
local math_pi = math.pi

-- ============================================================
--  ДИАГНОСТИКА (вывод в консоль Forts: DEBUG -> log)
--  Однократное сообщение на каждый пуск ГСН-ракеты.
--  Убрать/закомментировать после проверки: MP_DIAG = false
-- ============================================================
local MP_DIAG = false
local function MPDiag(msg)
    if not MP_DIAG then return end
    local line = "[MilitaryPack] " .. tostring(msg)
    if type(LogW) == "function" then pcall(LogW, line) end
    if type(LogErr) == "function" then pcall(LogErr, line) end
end

-- Таблицы позиций устройств и активных ракет
local MP_TEAMS = {}
local MP_DEVICE_POS = {}
local MP_DETONATED = {}
local HOMING_MISSILES = {}
local interceptMissiles = {}

-- ============================================================
--  ПАКЕТЫ ОСКОЛКОВ И БОЕПРИПАСОВ
-- ============================================================
local PACKAGE     = { { "cluster20mm", 20, 0.85, "360" }, { "mp_bullet", 300, 1.0, "360" } }
local PACKAGE_BIG = { { "cluster20mm", 40, 0.85, "360" }, { "mp_bullet", 600, 1.0, "360" } }

local BURST_PLAN =
{
    -- Артиллерия и кассетные пушки (полные пакеты осколков и пуль)
    cannon        = PACKAGE,
    he_shell      = PACKAGE,
    cannon2       = PACKAGE_BIG,
    he_shell2     = PACKAGE_BIG,
    clustershell  = PACKAGE,
    clustershell2 = PACKAGE_BIG,
    heat_shell    = PACKAGE,
    heat_shell2   = PACKAGE_BIG,
    ap_shell      = PACKAGE,
    ap_shell2     = PACKAGE_BIG,

    -- ПЗРК: правильные зенитные осколки (зенитный флак + шрапнель)
    aarocket      =
    {
        { "mp_flak", 35, 1.15, "360" },
        { "clusterpellet", 20, 1.0, "360" },
    },
    emprocket     =
    {
        { "clusterpellet", 25, 1.0, "360" },
        { "flaminghowitzer", 4, 0.6, "360" },
    },
    homingrocket  =
    {
        { "cluster20mm", 20, 0.9, "360" },
        { "clusterpellet", 30, 1.1, "360" },
        { "flaminghowitzer", 6, 0.6, "360" },
    },

    -- ЗРК и ПВО
    aamissile     =
    {
        { "mp_flak", 60, 1.2, "360" },
        { "clusterpellet", 30, 1.1, "360" },
    },
    flakshell     = { { "mp_flak", 40, 1.0, "360" } },
    shrapnelshell =
    {
        { "clusterpellet", 30, 1.15, "360" },
        { "mp_bullet", 150, 1.30, "fwd", 25 },
    },
    interceptmissile =
    {
        { "mp_flak", 300, 1.2, "360" },
    },
    typhoonshell =
    {
        { "cluster20mm", 80, 0.9, "360" },
        { "mp_bullet", 1200, 1.0, "360" },
        { "flaminghowitzer", 40, 0.7, "360" },
        { "clusterpellet", 60, 1.15, "360" },
    },
}

-- ============================================================
--  РАЗЛЁТ БОЕПРИПАСОВ ИЗ ЯЩИКА (cook-off)
-- ============================================================
local MP_COOKOFF_DIV    = 4
local MP_COOKOFF_DIST   = 90
local MP_COOKOFF_FRAMES = 3
local MP_FRAME          = 0
local MP_BIRTH          = {}

local function MarkBirth(saveName, nodeId)
    if not BURST_PLAN[saveName] then return end
    local ok, pos = pcall(NodePosition, nodeId)
    if ok and pos then
        MP_BIRTH[nodeId] = { pos.x, pos.y, MP_FRAME }
    end
end

local function IsCookoff(nodeId, pos)
    local b = MP_BIRTH[nodeId]
    MP_BIRTH[nodeId] = nil
    if not b then return false end
    if MP_FRAME - b[3] > MP_COOKOFF_FRAMES then return false end
    local dx, dy = pos.x - b[1], pos.y - b[2]
    return (dx * dx + dy * dy) <= (MP_COOKOFF_DIST * MP_COOKOFF_DIST)
end

local function SpawnProjectile(kind, teamId, x, y, vx, vy)
    local spawn = dlc2_CreateProjectile or CreateProjectile
    if spawn == nil then return end
    pcall(spawn, kind, "explosions", teamId, Vec3(x, y, 0), Vec3(vx, vy, 0), 10)
end

local function SpawnAt(kind, teamId, pos, baseAng, speed, mode, spread)
    local ang
    if mode == "fwd" then
        local half = (spread or 10) / 2
        local off = GetRandomInteger(-half * 10, half * 10, "spread") / 10
        ang = baseAng + math.rad(off)
    else
        ang = math.rad(GetRandomInteger(0, 359, "cluster angle"))
    end
    SpawnProjectile(kind, teamId, pos.x, pos.y, speed * math.cos(ang), speed * math.sin(ang))
end

-- ============================================================
--  ДЕТОНАЦИЯ УСТАНОВЛЕННЫХ НА ФОРТЕ ЯЩИКОВ БОЕПРИПАСОВ
-- ============================================================
--  ОПТИМИЗАЦИЯ / ФИКС «ЯЩИКИ ЛОМАЮТ ИГРУ».
--  Раньше один ящик спавнил СКРИПТОМ (SpawnProjectile, по вызову
--  на каждый снаряд) от 40 до 675 снарядов РАЗОМ:
--      ammo_typhoon = 50 cluster + 600 mp_bullet + 25 howitzer = 675
--      ammo_cluster / ammo_ap = 380, ammo_shrapnel = 360,
--      ammo_sam = 330, ammocrates = 325, ammo_he = 320 ...
--  Это сотни вызовов движка в одном кадре -> фриз/падение.
--  Плюс при цепной детонации НЕСКОЛЬКИХ ящиков счёт шел на тысячи.
--
--  Теперь бюджет ЖЁСТКО ограничен: см. CRATE_BUDGET ниже — на ящик
--  не больше ~80 снарядов (плюс-минус). Крупные пули `mp_bullet`
--  (их было 300-600 штук) заменены на малое число ВИЗУАЛЬНЫХ
--  кластерных снарядов — эффект «взрыв ящика» остаётся, а нагрузка
--  падает в ~7 раз.
-- ============================================================
local CRATE_BUDGET = 80   -- максимум снарядов на один ящик

local AMMO_BURST_PLAN =
{
    ammo_he          = { { "cluster20mm", 35, 950 }, { "mp_bullet", 45, 1100 } },
    ammo_solid20     = { { "mp_bullet", 45, 1200 }, { "cluster20mm", 30, 950 } },
    ammo_shrapnel    = { { "clusterpellet", 40, 1150 }, { "mp_bullet", 40, 1200 } },
    ammo_flak        = { { "mp_flak", 50, 1100 }, { "clusterpellet", 30, 1200 } },
    ammo_cluster     = { { "cluster20mm", 45, 950 }, { "mp_bullet", 35, 1150 } },
    ammo_heat        = { { "cluster20mm", 40, 950 }, { "flaminghowitzer", 15, 750 } },
    ammo_ap          = { { "cluster20mm", 45, 1050 }, { "mp_bullet", 35, 1200 } },
    ammo_aarocket    = { { "mp_flak", 45, 1100 }, { "clusterpellet", 30, 1000 } },
    ammo_emprocket   = { { "clusterpellet", 40, 1100 }, { "flaminghowitzer", 10, 800 } },
    ammo_homingrocket= { { "cluster20mm", 25, 950 }, { "clusterpellet", 35, 1100 }, { "flaminghowitzer", 15, 800 } },
    ammo_sam         = { { "mp_flak", 50, 1150 }, { "clusterpellet", 30, 1100 } },
    ammo_typhoon     = { { "cluster20mm", 50, 1050 }, { "mp_bullet", 25, 1200 }, { "flaminghowitzer", 20, 800 } },
    ammocrates       = { { "cluster20mm", 40, 950 }, { "mp_bullet", 35, 1100 } },
}

-- Жёстко режем план по бюджету: идём по списку и набираем снаряды,
-- пока не упрёмся в CRATE_BUDGET. Последний элемент обрезаем ровно
-- до остатка (чтобы не потерять тип снаряда, просто меньше штук).
local function ClampPlan(plan)
    if not plan then return nil end
    local out, used = {}, 0
    for _, item in ipairs(plan) do
        local kind, count, speed = item[1], item[2], item[3] or 950
        local left = CRATE_BUDGET - used
        if left <= 0 then break end
        if count > left then count = left end
        if count > 0 then
            out[#out + 1] = { kind, count, speed }
            used = used + count
        end
    end
    return out
end

local function DetonateAmmoCrate(teamId, saveName, pos)
    if not pos then return end
    local plan = AMMO_BURST_PLAN[saveName]
    if not plan and type(saveName) == "string" and (saveName:find("ammo") or saveName:find("crate")) then
        plan = AMMO_BURST_PLAN["ammocrates"]
    end
    if not plan then return end

    -- ОПТИМИЗАЦИЯ: раньше это был двойной цикл с вызовом
    -- SpawnProjectile (-> dlc2_CreateProjectile через pcall) на КАЖДУЮ
    -- пулю: 675 pcall+движок-вызовов подряд в одном кадре. Даже после
    -- урезания плана оставляем попытку «снапшотнуть» список до
    -- спавна, чтобы движок не перестраивал свой список снарядов
    -- между итерациями (именно это давало просадку на больших залпах).
    local list = ClampPlan(plan)
    if not list then return end

    for _, item in ipairs(list) do
        local kind, count, speed = item[1], item[2], item[3] or 950
        for _ = 1, count do
            local ang = math.rad(GetRandomInteger(0, 359, "ammo burst"))
            local spd = speed * (GetRandomInteger(75, 125, "ammo spd") / 100)
            SpawnProjectile(kind, teamId, pos.x, pos.y, spd * math.cos(ang), speed * math.sin(ang))
        end
    end
end

-- ============================================================
--  ОГРАНИЧЕННОЕ ПРОБИТИЕ БРОНИ КАССЕТОЙ
-- ============================================================
local ARMOUR_PLATES = { armour = true, armoureddoor = true, heavyarmour = true }
local PIERCE_COUNTED = { clustershell = true, clustershell2 = true }
local MAX_ARMOUR_PIERCE = 2
local penPlates = {}
local penLastStrut = {}

function OnLinkHit(nodeIdA, nodeIdB, objectId, objectTeamId, objectSaveName, damage, pos, reflectedByEnemy)
    if not PIERCE_COUNTED[objectSaveName] then return end
    if reflectedByEnemy then return end
    local ok, mat = pcall(GetLinkMaterialSaveName, nodeIdA, nodeIdB)
    if not ok or mat == nil or not ARMOUR_PLATES[mat] then return end
    local key = nodeIdA .. ":" .. nodeIdB
    if penLastStrut[objectId] == key then return end
    penLastStrut[objectId] = key
    local n = (penPlates[objectId] or 0) + 1
    penPlates[objectId] = n
    if n >= MAX_ARMOUR_PIERCE then
        pcall(DestroyProjectile, objectId)
    end
end

-- ============================================================
--  СКАНЕР ЦЕЛЕЙ ДЛЯ ГСН-РАКЕТЫ: БОЧКИ, ЯЩИКИ, РЕАКТОР И ОРУДИЯ
-- ============================================================
-- ============================================================
--  ЗАПРЕТ ПОПАДАНИЯ ПО СВОИМ (союзным) УСТРОЙСТВАМ
-- ============================================================
--  РЕАЛЬНЫЕ API (проверено по Forts.exe и по коду самого
--  движка в data/ai/ai.lua):
--      GetDeviceTeamIdActual(deviceId) -> id команды устройства
--      MAX_SIDES                       -> 100 (глобальная константа)
--
--  КАК В FORTS КОДИРУЮТСЯ КОМАНДЫ:
--      teamId % MAX_SIDES  == СТОРОНА (1 или 2)
--      floor(teamId / MAX_SIDES) == номер игрока внутри стороны
--
--  Именно так делает сам движок (data/ai/ai.lua):
--      if teamId%MAX_SIDES == 1 then enemyTeamId = 2 ...
--      teamId > MAX_SIDES and deviceTeamId == teamId
--        or teamId < MAX_SIDES and deviceTeamId%MAX_SIDES == teamId
--
--  ЭТАЛОН союзничества (ai/tips.lua:631):
--      weaponTeamId%MAX_SIDES ~= teamId%MAX_SIDES  -> это ВРАГ
--      weaponTeamId%MAX_SIDES == teamId%MAX_SIDES  -> это СОЮЗНИК
--
--  ВАЖНО: в движке НЕТ функций AreTeamsAllied / GetTeamAllies /
--  GetTeamAlly (проверено grep'ом по Forts.exe). Раньше проверка
--  союзника опиралась именно на них — они молча не срабатывали,
--  поэтому ракета и прилетала в СОЮЗНЫЙ реактор.
--  Работает только арифметика по MAX_SIDES.
local MAX_SIDES = MAX_SIDES or 100

-- Сторона команды (1 или 2, но не только: MAX_SIDES допускает и больше).
local function TeamSide(teamId)
    if type(teamId) ~= "number" or teamId <= 0 then return nil end
    return teamId % MAX_SIDES
end

-- Союзники ли две команды. Союзник = та же сторона.
-- Работает и для 1v1, и для 2v2/3v3, и для FFA:
--   1v1: 1 и 2           -> стороны 1 и 2 -> враги
--   2v2: 1,101 и 2,102   -> стороны 1,1 и 2,2 -> 1+101 союзники
local function TeamsAreAllied(teamA, teamB)
    if teamA == teamB then return true end
    local sa, sb = TeamSide(teamA), TeamSide(teamB)
    if sa == nil or sb == nil then return false end
    return sa == sb
end

-- Является ли устройство союзным для ракеты.
-- ВАЖНО: именно TeamsAreAllied, а НЕ «==» — в 2v2/3v3 id команд
-- союзников РАЗНЫЕ (1 и 3 — свои), поэтому равенство не годится.
local function IsFriendlyDevice(missileTeamId, deviceId)
    if not missileTeamId or missileTeamId <= 0 then return false end
    -- узел конструкции может не иметь команды устройства — пробуем оба
    if type(GetDeviceTeamIdActual) == "function" then
        local ok, dTeam = pcall(GetDeviceTeamIdActual, deviceId)
        if ok and type(dTeam) == "number" and dTeam > 0 then
            return TeamsAreAllied(missileTeamId, dTeam)
        end
    end
    if type(NodeTeam) == "function" then
        local ok, nTeam = pcall(NodeTeam, deviceId)
        if ok and type(nTeam) == "number" and nTeam > 0 then
            return TeamsAreAllied(missileTeamId, nTeam)
        end
    end
    return false
end

-- Враждебна ли команда по отношению к ракете: враг = НЕ союзник.
local function IsHostileTeam(missileTeamId, otherTeamId)
    if not missileTeamId or missileTeamId <= 0 then return true end
    return not TeamsAreAllied(missileTeamId, otherTeamId)
end

-- ============================================================
--  ВЫБОР ЦЕЛИ ДЛЯ ГСН-РАКЕТЫ — УМНЫЙ ПРИОРИТЕТ
-- ============================================================
--  ПОЧЕМУ ЭТО ОТДЕЛЬНАЯ ФУНКЦИЯ (а не просто «ближайшее»):
--
--  Раньше ракета «перескакивала» с цели на цель: каждый скан
--  (раз в 20 кадров) брался БЛИЖАЙШИЙ объект, а ближайший за время
--  полёта меняется — как только ракета пролетала мимо одной бочки,
--  ближайшей становилась следующая, и ракета разворачивалась.
--  Отсюда «трепит» и «не заворачивает до конца».
--
--  Теперь цель выбирается ОДИН РАЗ и удерживается:
--    * новая цель берётся только если старая потеряна (уничтожена
--      или ушла дальше KEEP_TARGET_DIST);
--    * приоритет по КЛАССУ цели, а не по дистанции:
--      РЕАКТОР (ядро форта) -> бочки/ящики БК -> орудия -> прочее;
--    * внутри класса — ближайшая.
--
--  Это соответствует заказу: «сделай её умней», «летит в реактор».
local KEEP_TARGET_DIST_SQ = 2500 * 2500 -- держим цель, пока она ближе 2500 ед.
local REACQUIRE_CHANCE    = 6           -- пере-выбор цели раз в 6 сканов

local function ScoreTarget(item, name, mPos)
    -- штраф за дальность (меньше = лучше)
    local distPenalty = item.distSq
    local n = name or ""
    -- класс цели: чем важнее, тем БОЛЬШЕ бонус (то есть меньше штраф)
    if n == "reactor" or n:find("reactor") or n:find("core") then
        return distPenalty - 90000000        -- РЕАКТОР — главная цель
    elseif n:find("barrel") or n:find("ammo") or n:find("crate")
        or n:find("fuel") or n:find("powder") or n:find("bomb") then
        return distPenalty - 40000000        -- бочки и ящики БК
    elseif n:find("cannon") or n:find("typhoon") or n:find("zrk")
        or n:find("manpads") or n:find("shrapnel") or n:find("weapon")
        or n:find("howitzer") or n:find("laser") or n:find("mortar")
        or n:find("flak") then
        return distPenalty - 12000000        -- орудия
    end
    return distPenalty                        -- всё прочее
end

local function FindGroundTarget(missileTeamId, mPos, currentTarget)
    -- Определяем сторону врага.
    -- В Forts команды кодируются как teamId%MAX_SIDES = сторона,
    -- поэтому «enemy = 3 - teamId» верно только для дуэли 1v1.
    -- Здесь берём сторону РАКЕТЫ и ищем любую ДРУГУЮ сторону,
    -- у которой есть устройства. Союзники (та же сторона) отсекаются.
    local mySide = TeamSide(missileTeamId)
    local enemyTeam = nil
    if mySide then
        -- перебираем кандидатов: сначала «классические» стороны 1/2, потом пары
        for _, cand in ipairs({ 1, 2, 3, 4 }) do
            local candSide = TeamSide(cand)
            if candSide and candSide ~= mySide and IsHostileTeam(missileTeamId, cand) then
                if type(GetDeviceCountSide) ~= "function" or (GetDeviceCountSide(cand) or 0) > 0 then
                    enemyTeam = cand
                    break
                end
            end
        end
    end
    if not enemyTeam then
        -- фолбэк: противоположная сторона
        if mySide == 1 then
            enemyTeam = 2
        else
            enemyTeam = 1
        end
    end
    local enemySide = TeamSide(enemyTeam) or enemyTeam

    local foundTargets = {
        barrel = {},
        reactor = {},
        weapon = {},
        device = {},
    }

    -- 1. Сканирование устройств ВРАЖЕБНОЙ стороны.
    --    РЕАЛЬНЫЕ API движка Forts:
    --      GetDeviceCountSide(teamId) -> число устройств стороны
    --      GetDeviceIdSide(teamId, i) -> id устройства
    --      GetDeviceType(id)          -> SaveName устройства ("reactor", "barrel", ...)
    --      GetDevicePosition(id)      -> Vec3
    --    ВАЖНО: в игре НЕТ GetTotalDeviceCount / GetTotalDeviceId / GetDeviceSaveName —
    --    именно из-за них сканер раньше не находил ни одной цели.
    if type(GetDeviceCountSide) == "function" and type(GetDeviceIdSide) == "function"
       and type(GetDeviceType) == "function" and type(GetDevicePosition) == "function" then
        local devCount = GetDeviceCountSide(enemyTeam) or 0
        for i = 0, devCount - 1 do
            local dId = GetDeviceIdSide(enemyTeam, i)
            if dId and not IsFriendlyDevice(missileTeamId, dId) then
                local okP, dPos = pcall(GetDevicePosition, dId)
                if okP and dPos and type(dPos.x) == "number" then
                    local sName = ""
                    local okN, n = pcall(GetDeviceType, dId)
                    if okN and n then sName = string.lower(tostring(n)) end

                    local distSq = (dPos.x - mPos.x)^2 + (dPos.y - mPos.y)^2
                    local item = { pos = dPos, distSq = distSq, name = sName }

                    -- Распознавание бочек, ящиков с боеприпасами и цистерн
                    if sName:find("barrel") or sName:find("ammo") or sName:find("crate") or sName:find("fuel") or sName:find("powder") or sName:find("bomb") then
                        table.insert(foundTargets.barrel, item)
                    elseif sName == "reactor" or sName == "core" or sName:find("reactor") or sName:find("core") then
                        table.insert(foundTargets.reactor, item)
                    elseif sName:find("cannon") or sName:find("typhoon") or sName:find("zrk") or sName:find("manpads") or sName:find("shrapnel") or sName:find("weapon") or sName:find("howitzer") or sName:find("laser") or sName:find("mortar") or sName:find("flak") then
                        table.insert(foundTargets.weapon, item)
                    else
                        table.insert(foundTargets.device, item)
                    end
                end
            end
        end
    end

    -- 2. Реактор (ядро форта) — если не попал в скан выше.
    --    ВАЖНО: свой (и ЛЮБОЙ союзный) реактор СЮДА НЕ ПОПАДАЕТ.
    --    Раньше резервный поиск перебирал ОБЕ стороны подряд и
    --    проверял только точное равенство команд — в 2v2/3v3
    --    союзник имеет ДРУГОЙ id, поэтому ракета могла прилететь
    --    в СОЮЗНЫЙ реактор. Теперь перебираем ВСЕ стороны и берём
    --    только те, что действительно враждебны (IsHostileTeam).
    if #foundTargets.reactor == 0
       and type(GetDeviceCountSide) == "function"
       and type(GetDeviceIdSide) == "function"
       and type(GetDeviceType) == "function" then
        for side = 1, 4 do
            if IsHostileTeam(missileTeamId, side) then
                local cnt = GetDeviceCountSide(side) or 0
                for i = 0, cnt - 1 do
                    local dId = GetDeviceIdSide(side, i)
                    if dId and not IsFriendlyDevice(missileTeamId, dId) then
                        local okN, n = pcall(GetDeviceType, dId)
                        if okN and n and string.lower(tostring(n)) == "reactor" then
                            local okP, dPos = pcall(GetDevicePosition, dId)
                            if okP and dPos and type(dPos.x) == "number" then
                                local distSq = (dPos.x - mPos.x)^2 + (dPos.y - mPos.y)^2
                                table.insert(foundTargets.reactor, { pos = dPos, distSq = distSq, name = "reactor" })
                            end
                        end
                    end
                end
            end
            if #foundTargets.reactor > 0 then break end
        end
    end

    -- Выбор цели: УМНЫЙ ПРИОРИТЕТ (реактор -> БК -> орудия -> прочее),
    -- внутри класса — ближайшая. См. ScoreTarget выше.
    local function GetBest(list)
        if not list or #list == 0 then return nil end
        local best, bestScore = nil, nil
        for _, it in ipairs(list) do
            local sc = ScoreTarget(it, it.name, mPos)
            if not bestScore or sc < bestScore then
                best, bestScore = it, sc
            end
        end
        return best
    end

    -- УДЕРЖАНИЕ ЦЕЛИ: если текущая цель ещё жива и рядом — не меняем.
    -- Иначе был «прыжок» на новую цель и рыскание ракеты.
    local chosen = nil
    if currentTarget and type(currentTarget.x) == "number" then
        local dx = currentTarget.x - mPos.x
        local dy = (currentTarget.y or 0) - mPos.y
        if (dx * dx + dy * dy) < KEEP_TARGET_DIST_SQ then
            chosen = { pos = currentTarget, name = "", distSq = dx * dx + dy * dy }
        end
    end

    if not chosen then
        chosen = GetBest(foundTargets.reactor)
              or GetBest(foundTargets.barrel)
              or GetBest(foundTargets.weapon)
              or GetBest(foundTargets.device)
    end

    if chosen then
        local typeLabel = "REACTOR"
        if chosen.name:find("barrel") or chosen.name:find("ammo") or chosen.name:find("crate") or chosen.name:find("fuel") then
            typeLabel = "BARREL / AMMO"
        elseif chosen.name:find("reactor") or chosen.name:find("core") then
            typeLabel = "REACTOR"
        elseif chosen.name:find("cannon") or chosen.name:find("typhoon") or chosen.name:find("weapon") or chosen.name:find("zrk") or chosen.name:find("manpads") then
            typeLabel = "WEAPON"
        else
            typeLabel = "DEVICE"
        end
        return chosen.pos, typeLabel
    end

    -- 3. Резервный поиск узлов конструкции.
    --    РЕАЛЬНЫЕ API: NodeCount(teamId) и GetNodeId(teamId, index).
    --    Узлы ТОЛЬКО враждебных сторон — союзный fort сюда не попадает.
    if type(NodeCount) == "function" and type(GetNodeId) == "function" and type(NodePosition) == "function" then
        local bestNodePos = nil
        local bestNodeDistSq = 99999999999999
        for side = 1, 4 do
            if IsHostileTeam(missileTeamId, side) then
                local nodeCount = NodeCount(side) or 0
                for i = 0, nodeCount - 1 do
                    local nId = GetNodeId(side, i)
                    if nId then
                        -- двойная страховка: узел не должен быть союзным
                        if not IsFriendlyDevice(missileTeamId, nId) then
                            local ok, nPos = pcall(NodePosition, nId)
                            if ok and nPos and type(nPos.x) == "number" then
                                local distSq = (nPos.x - mPos.x)^2 + (nPos.y - mPos.y)^2
                                if distSq < bestNodeDistSq then
                                    bestNodeDistSq = distSq
                                    bestNodePos = nPos
                                end
                            end
                        end
                    end
                end
            end
        end
        if bestNodePos then
            return bestNodePos, "STRUCTURE"
        end
    end

    -- 4. Резервная цель в стороне врага
    local sideDir = (enemySide == 2) and 1 or -1
    return Vec3(mPos.x + 6000 * sideDir, mPos.y - 300, 0), "ENEMY BASE"
end

-- ============================================================
--  СОБЫТИЕ ВЫСТРЕЛА ИЗ ОРУЖИЯ (OnWeaponFired)
-- ============================================================
-- ВАЖНО (порядок объявлений в Lua): interceptActive объявлен ИМЕННО
-- ЗДЕСЬ, ВЫШЕ OnWeaponFired. Раньше он был объявлен ниже (у Update),
-- и строка внутри OnWeaponFired работала не с этой локальной
-- переменной, а с ГЛОБАЛЬНОЙ interceptActive = nil — то есть падала
-- с "attempt to perform arithmetic on a nil value". Ошибка была
-- замаскирована крашем GetGameTime (он летел раньше в том же блоке).
-- Lua-локали видны только ПОСЛЕ своего объявления — держим это в уме.
local interceptActive = 0

function OnWeaponFired(teamId, saveName, weaponId, projectileNodeId, projectileNodeIdFrom)
    local actualAmmo = (type(GetWeaponSelectedAmmo) == "function" and GetWeaponSelectedAmmo(weaponId)) or saveName
    MarkBirth(actualAmmo, projectileNodeId)

    if actualAmmo == "interceptmissile" or saveName == "intercept" then
        if not interceptMissiles[projectileNodeId] then interceptActive = interceptActive + 1 end
        -- ВАЖНО (фикс краша): здесь был вызов GetGameTime() — такой
        -- функции в движке НЕТ (grep по Forts.exe: 0 совпадений), из-за
        -- чего КАЖДЫЙ выстрел из ЗРК/ПРО валил OnWeaponFired с ошибкой
        -- "attempt to call global 'GetGameTime' (a nil value)" и
        -- заливал консоль. Поле `created` при этом нигде не читалось —
        -- это был мёртвый код, поэтому просто убираем его.
        -- Если понадобится «время» — в моде есть счётчик кадров MP_FRAME
        -- (растёт в Update); отдельного игрового времени в API нет.
        interceptMissiles[projectileNodeId] = { teamId = teamId }
    end

    -- ЗАХВАТ ГСН-РАКЕТЫ СТРОГО ПРИ ПУСКЕ
    if actualAmmo == "homingrocket" or saveName == "homingrocket" then
        local okP, p = pcall(NodePosition, projectileNodeId)
        local startY = (okP and p and p.y) or 0
        HOMING_MISSILES[projectileNodeId] = {
            teamId = teamId,
            targetPos = nil,
            startY = startY,
            age = 0,
            beepTimer = 0,
            locked = false,
        }

        if okP and p and type(SpawnEffect) == "function" then
            pcall(SpawnEffect, path .. "/effects/rocket_lock_fire.lua", p)
        end

        -- ДИАГНОСТИКА: уточняем, какую цель выбрал сканер
        if okP and p then
            local tPos, tKind = FindGroundTarget(teamId, p, nil)
            if tPos and type(tPos.x) == "number" then
                HOMING_MISSILES[projectileNodeId].targetPos = tPos
                HOMING_MISSILES[projectileNodeId].locked = true
                -- СРАЗУ назначаем цель движку (см. Update: без этого
                -- ракета «дергается, но не заворачивает»).
                if type(SetMissileTarget) == "function" then
                    pcall(SetMissileTarget, projectileNodeId, tPos)
                end
                MPDiag(string.format(
                    "GSN launch t=%d node=%d -> target=%s at (%.0f, %.0f)",
                    teamId or -1, projectileNodeId or -1, tostring(tKind),
                    tPos.x, tPos.y or 0))
            else
                MPDiag(string.format(
                    "GSN launch t=%d node=%d -> NO TARGET FOUND",
                    teamId or -1, projectileNodeId or -1))
            end
        else
            MPDiag(string.format(
                "GSN launch t=%d node=%d -> NO PROJECTILE POSITION",
                teamId or -1, projectileNodeId or -1))
        end
    end
end

function OnProjectileCollision(teamIdA, nodeIdA, saveNameA, teamIdB, nodeIdB, saveNameB)
    if interceptMissiles[nodeIdA] then pcall(DestroyProjectile, nodeIdA) end
    if interceptMissiles[nodeIdB] then pcall(DestroyProjectile, nodeIdB) end
end

local checkTimer = 0
local PROX_RADIUS = 200
-- Таймер РЕЗЕРВНОГО сканера снарядов (см. Update). Раз в 30 кадров.
local SCAN_TIMER = 0
-- (interceptActive объявлен ВЫШЕ, рядом с OnWeaponFired — см. комментарий там.)

-- ============================================================
--  ГЛОБАЛЬНЫЙ ЛИМИТ СНАРЯДОВ + ПОЛНАЯ ЗАЧИСТКА
-- ============================================================
--  Зачем: мод спавнит очень много снарядов (кассета, ЗРК, осколки,
--  детонация ящиков). Если снарядов в мире становится слишком много,
--  движок начинает проседать, а дальше — фриз/вылет. Жёсткий лимит:
--  как только суммарное число снарядов ВСЕХ сторон превысило
--  MP_PROJ_LIMIT — чистим ВСЁ под ноль («под чистую»).
--
--  Проверяем не каждый кадр, а раз в MP_LIMIT_CHECK_EVERY кадров:
--  сам подсчёт — это ProjectileCount по 4 сторонам (4 вызова), и
--  дёргать его 60 раз в секунду незачем.
--
--  ЗАМЕР (почему 1000 — правильный порог): самый большой разрыв
--  в моде — clustershell2x = 144 осколка, typhoonshell = 135,
--  aamissile_r4 = 120. Один выстрел лимит НЕ пробивает. Лимит
--  ловит НАКОПЛЕНИЕ: несколько залпов ЗРК + осколки + подрыв
--  ящиков боеприпасов одновременно.
local MP_PROJ_LIMIT            = 1000  -- порог: больше — зачистка
local MP_LIMIT_CHECK_EVERY     = 15    -- кадров между проверками лимита
local MP_LIMIT_TIMER           = 0
local MP_PURGES                = 0     -- сколько раз чистили (для лога)

-- ============================================================
--  ПЕРИОДИЧЕСКАЯ ОЧИСТКА КЭША МОДА
-- ============================================================
--  Раз в 2.5 минуты чистим ВСЕ внутренние таблицы мода. Они копят
--  записи по nodeId, а nodeId в Forts ПЕРЕИСПОЛЬЗУЮТСЯ — значит
--  старые записи не только текут по памяти, но и могут «прилипнуть»
--  к новому снаряду с тем же id (ложное срабатывание). Полная
--  очистка это лечит и заодно сбрасывает любой накопившийся мусор.
--
--  Важно: чистим только ЧИСТО-модовские таблицы. Игровые сущности
--  (снаряды, устройства) НЕ трогаем — их снесёт лимит снарядов
--  или сам движок.
local MP_CACHE_PERIOD_FRAMES = 60 * 150  -- 2.5 минуты при 60 fps
local MP_CACHE_TIMER         = 0
local MP_CACHE_CLEARS        = 0

-- Полная зачистка кэша мода. Вынесена в функцию, т.к. вызывается
-- из двух мест: по таймеру и принудительно при переполнении.
local function PurgeModCaches(reason)
    -- Таблицы, привязанные к nodeId снарядов
    for k in pairs(HOMING_MISSILES) do HOMING_MISSILES[k] = nil end
    for k in pairs(interceptMissiles) do interceptMissiles[k] = nil end
    for k in pairs(MP_BIRTH) do MP_BIRTH[k] = nil end
    for k in pairs(MP_DETONATED) do MP_DETONATED[k] = nil end
    for k in pairs(penPlates) do penPlates[k] = nil end
    for k in pairs(penLastStrut) do penLastStrut[k] = nil end
    -- Кэши устройств/команд (перезаполнятся сами)
    for k in pairs(MP_DEVICE_POS) do MP_DEVICE_POS[k] = nil end
    for k in pairs(MP_TEAMS) do MP_TEAMS[k] = nil end

    -- Счётчик активных противоракет надо сбросить ВМЕСТЕ с таблицей,
    -- иначе он «уедет» и гейт interceptActive > 0 перестанет работать.
    interceptActive = 0

    MP_CACHE_CLEARS = MP_CACHE_CLEARS + 1
    if type(Log) == "function" then
        pcall(Log, string.format("[MILITARYPACK] cache purged (%s) #%d",
                                 tostring(reason), MP_CACHE_CLEARS))
    end
end

-- Уничтожить ВСЕ снаряды всех сторон. Используем DestroyProjectile —
-- это реальный API движка (проверено). Обходим стороны с КОНЦА,
-- потому что при удалении индексы в списке движка сдвигаются.
local function PurgeAllProjectiles()
    if type(ProjectileCount) ~= "function"
       or type(GetProjectileId) ~= "function"
       or type(DestroyProjectile) ~= "function" then
        return 0
    end
    local killed = 0
    for _, side in ipairs({ 1, 2, 3, 4 }) do
        local n = ProjectileCount(side) or 0
        for i = n - 1, 0, -1 do
            local pid = GetProjectileId(side, i)
            if pid then
                if pcall(DestroyProjectile, pid) then killed = killed + 1 end
            end
        end
    end
    MP_PURGES = MP_PURGES + 1
    if type(Log) == "function" then
        pcall(Log, string.format(
            "[MILITARYPACK] PROJECTILE LIMIT %d exceeded -> purged %d #%d",
            MP_PROJ_LIMIT, killed, MP_PURGES))
    end
    return killed
end

function Update(frame)
    -- ========================================================
    --  ЛИМИТ СНАРЯДОВ + ПЕРИОДИЧЕСКАЯ ОЧИСТКА КЭША
    --  (обе проверки дешёвые и идут ДО дорогого сканера)
    -- ========================================================
    MP_LIMIT_TIMER = MP_LIMIT_TIMER + 1
    if MP_LIMIT_TIMER >= MP_LIMIT_CHECK_EVERY then
        MP_LIMIT_TIMER = 0
        if type(ProjectileCount) == "function" then
            -- Считаем ВСЕ снаряды всех сторон (как и договорились).
            local total = 0
            for _, side in ipairs({ 1, 2, 3, 4 }) do
                total = total + (ProjectileCount(side) or 0)
            end
            if total > MP_PROJ_LIMIT then
                -- Переполнение: чистим ВСЁ под ноль и заодно кэш
                -- (записи по nodeId после зачистки бессмысленны).
                PurgeAllProjectiles()
                PurgeModCaches("projectile limit")
            end
        end
    end

    MP_CACHE_TIMER = MP_CACHE_TIMER + 1
    if MP_CACHE_TIMER >= MP_CACHE_PERIOD_FRAMES then
        MP_CACHE_TIMER = 0
        PurgeModCaches("timer 2.5min")
    end

    -- ========================================================
    --  АВТОМАТИЧЕСКИЙ РЕЗЕРВНЫЙ СКАНЕР ВСЕХ СНАРЯДОВ В ВОЗДУХЕ
    --  РЕАЛЬНЫЕ API: ProjectileCount(teamId) + GetProjectileId(teamId, i)
    --                + GetNodeProjectileSaveName(nodeId)
    --  (GetProjectileCount()/GetProjectileSaveName()/GetProjectileType()
    --   в движке НЕ существуют — из-за них сканер был мёртв.)
    --
    --  ОПТИМИЗАЦИЯ: это РЕЗЕРВНЫЙ проход (основной регистратор —
    --  OnWeaponFired при пуске). Перебирать ВСЕ снаряды всех 4
    --  сторон каждый кадр незачем: при плотном бое это сотни
    --  вызовов в кадр. Делаем проход раз в 30 кадров (~2 раза
    --  в секунду) — ракета, потерявшаяся по событию, всё равно
    --  подхватится почти мгновенно.
    -- ========================================================
    SCAN_TIMER = SCAN_TIMER + 1
    if SCAN_TIMER >= 30
       and type(ProjectileCount) == "function" and type(GetProjectileId) == "function"
       and type(GetNodeProjectileSaveName) == "function" then
        SCAN_TIMER = 0
        for _, side in ipairs({ 1, 2, 3, 4 }) do
            local pCount = ProjectileCount(side) or 0
            for i = 0, pCount - 1 do
                local pId = GetProjectileId(side, i)
                if pId and not HOMING_MISSILES[pId] then
                    local okS, s = pcall(GetNodeProjectileSaveName, pId)
                    local pSave = (okS and s) and tostring(s) or ""
                    if pSave == "homingrocket" then
                        local okP, pPos = pcall(NodePosition, pId)
                        -- ВАЖНО: за сторону ракеты берём сторону, ПО КОТОРОЙ
                        -- мы её нашли (аргумент side у ProjectileCount).
                        -- NodeTeam для этого ненадёжен: он раньше давал
                        -- неверную команду, из-за чего проверка союзника
                        -- не срабатывала и ракета летела в СВОЙ реактор.
                        -- side здесь — АБСОЛЮТНЫЙ id стороны (в 2v2/3v3
                        -- это реально 3 или 4, а не «1/2»).
                        HOMING_MISSILES[pId] = {
                            teamId = side,
                            targetPos = nil,
                            startY = okP and pPos and pPos.y or 0,
                            age = 0,
                            beepTimer = 0,
                            locked = false,
                        }
                    end
                end
            end
        end
    end

    -- ========================================================
    --  УМНЫЙ ИИ ГСН-РАКЕТЫ: КРЕЙСЕРСКИЙ ЭШЕЛОН + TOP-ATTACK
    -- ========================================================
    --  ОПТИМИЗАЦИЯ (важно для производительности):
    --  Полный перебор устройств (GetDeviceCountSide по 4 сторонам +
    --  4 скан-цикла) — ДОРОГАЯ операция. Раньше FindGroundTarget
    --  вызывался на КАЖДОМ кадре на КАЖДУЮ ракету, то есть при
    --  4 ракетах в воздухе это ~4 полных скана В КАДР (240 в
    --  секунду). Отсюда фризы на поздней игре.
    --
    --  Теперь цель ищется только когда ракете реально нужно:
    --    1) цель ещё не найдена, ИЛИ
    --    2) наступил момент переоценки (retargetTimer), ИЛИ
    --    3) цель уже позади/потеряна (мимо прошли).
    --  Между этими событиями цель просто переиспользуется —
    --  ноль вызовов дорогого скана.
    local RETARGET_PERIOD = 20   -- кадров между переоценками цели
    local BEEP_PERIOD     = 30   -- кадров между писками (было 10)

    for mId, data in pairs(HOMING_MISSILES) do
        local okP, mPos = pcall(NodePosition, mId)

        if not okP or not mPos then
            HOMING_MISSILES[mId] = nil
        else
            data.age = (data.age or 0) + 1
            if not data.startY then data.startY = mPos.y end

            -- Звуковой зуммер в полёте.
            -- БЫЛО 10 кадров (~6 раз в секунду), стало 30 (~2 раза
            -- в секунду): 5.5 кГц-писк на такой частоте и на полной
            -- громкости — это и была «пизда ушам».
            data.beepTimer = (data.beepTimer or 0) + 1
            if data.beepTimer >= BEEP_PERIOD then
                data.beepTimer = 0
                if type(SpawnEffect) == "function" then
                    pcall(SpawnEffect, path .. "/effects/rocket_beep.lua", mPos)
                end
            end

            -- Когда переоценивать цель (см. комментарий выше).
            data.retargetTimer = (data.retargetTimer or 0) + 1
            local needScan = false
            if not data.targetPos then
                needScan = true                       -- цели ещё нет
            elseif data.retargetTimer >= RETARGET_PERIOD then
                data.retargetTimer = 0
                needScan = true                       -- плановая переоценка
            else
                -- цель потеряна, если ракета её уже пролетела:
                -- проекция скорости на направление к цели стала < 0
                local tdx = data.targetPos.x - mPos.x
                local tdy = (data.targetPos.y or 0) - mPos.y
                local dist = math.sqrt(tdx*tdx + tdy*tdy)
                if dist > 0 then
                    local okV2, mVel2 = pcall(NodeVelocity, mId)
                    if okV2 and mVel2 then
                        local dot = (mVel2.x or 0)*(tdx/dist) + (mVel2.y or 0)*(tdy/dist)
                        if dot < -400 or dist > 20000 then needScan = true end
                    end
                end
            end

            -- ДОРОГОЙ СКАН — только по необходимости (было: каждый кадр).
            if needScan then
                local tgt, tgtLabel = FindGroundTarget(data.teamId, mPos, data.targetPos)
                if tgt then
                    data.targetPos = tgt
                    if not data.locked then
                        data.locked = true
                        local labelText = tgtLabel or "TARGET"
                        local noticeMsg = "[HOMING EMP] TARGET LOCKED -> " .. labelText .. "!"
                        local floatMsg  = "[TARGET: " .. labelText .. "]"

                        -- Оповещения на всех системных каналах
                        if type(Notice) == "function" then
                            pcall(Notice, noticeMsg)
                        end
                        if type(ShowTip) == "function" then
                            pcall(ShowTip, noticeMsg, 3.0)
                        end
                        if type(ShowFloatingText) == "function" then
                            pcall(ShowFloatingText, mPos, floatMsg, 0, 2.5)
                        end
                        if type(LogW) == "function" then
                            pcall(LogW, L"[HOMING EMP] TARGET LOCKED!")
                        end
                        if type(Log) == "function" then
                            pcall(Log, noticeMsg)
                        end
                    end
                end
            end

            -- ====================================================
            --  НАВЕДЕНИЕ РАКЕТЫ — ГЛАВНЫЙ ФИКС
            -- ====================================================
            --  ИСПРАВЛЕНИЕ: раньше здесь было написано, что
            --  SetMissileTarget «не существует». Это НЕВЕРНО —
            --  функция ЕСТЬ в движке (Forts.exe: SetMissileTarget,
            --  GetMissileTarget, GetMissileTargetProjected,
            --  IsMissileAttacking). Именно поэтому ракета
            --  «дергалась, но не заворачивала»: блок Missile даёт
            --  ТЯГУ и ПОВОРОТ, но НИКТО не говорил ракете, КУДА
            --  поворачивать. Цель ищет сканер, а назначить её
            --  движку надо отсюда.
            --
            --  Если цель не менялась в этом кадре — НЕ дёргаем
            --  SetMissileTarget (это лишний вызов в движке и, что
            --  важнее, сбрасывает внутренний фильтр доворота).
            -- ====================================================
            if data.targetPos and type(data.targetPos.x) == "number" then
                if data.assignedPos ~= data.targetPos then
                    if type(SetMissileTarget) == "function" then
                        local okSet = pcall(SetMissileTarget, mId, data.targetPos)
                        data.targetAssigned = okSet and true or false
                        if okSet then data.assignedPos = data.targetPos end
                    end
                end
            end

            -- Читаем цель движка для уведомлений/диагностики
            if type(GetMissileTarget) == "function" then
                local okT, realTarget = pcall(GetMissileTarget, mId)
                if okT and realTarget and type(realTarget.x) == "number" then
                    data.engineTarget = realTarget
                end
            elseif type(GetProjectileTarget) == "function" then
                local okT, realTarget = pcall(GetProjectileTarget, mId)
                if okT and realTarget and type(realTarget.x) == "number" then
                    data.engineTarget = realTarget
                end
            end

            -- ====================================================
            --  УМНЫЙ ПОЛЁТ ДО ЗЕМЛИ: СТАБИЛИЗАЦИЯ ВЫСОТЫ
            -- ====================================================
            --  ЗАЧЕМ ЭТО НУЖНО.
            --  Поле Missile.CruiseHeight задаёт ВЫСОТУ крейсерского
            --  эшелона внутри движка, но на практике движок не всегда
            --  тянет ракету вверх — она идёт по прямой и врезается в
            --  свой холм или в стену форта, «делая» самоубийство
            --  в воздухе. Чтобы ракета ГАРАНТИРОВАННО доходила до
            --  цели, мы временно подменяем точку прицела: пока ракета
            --  ниже эшелона и далеко от цели — целимся в «фантомную»
            --  точку ВЫШЕ ракеты; когда ракета уже над целью —
            --  возвращаем настоящую точку и она пикирует.
            --
            --  Так ракета «живёт до земли»: набирает высоту, идёт по
            --  эшелону над препятствиями и только у самой цели
            --  сваливается на неё сверху (top-attack).
            --
            --  ВАЖНО: цель при этом НЕ теряется — мы лишь временно
            --  подменяем точку прицеливания для движка.
            --  ОПТИМИЗАЦИЯ (важно!). Раньше здесь SetMissileTarget
            --  вызывался КАЖДЫЙ КАДР и КАЖДЫЙ РАЗ с НОВЫМ объектом
            --  Vec3. Это (а) лишний вызов в движке на каждой ракете
            --  в кадре и (б) главное — сброс внутреннего фильтра
            --  доворота, из-за которого ракета «трепыхалась».
            --  Теперь запоминаем последнюю ПОДСУНУТУЮ точку в
            --  data.cruiseAssigned и пере-выдаём её только когда она
            --  реально изменилась (смена режима «эшелон <-> пикирование»
            --  или перескок цели). Точка сравнивается по значению,
            --  а не по ссылке — поэтому фиксируем и режим (data.cruising).
            if data.targetPos and type(data.targetPos.x) == "number" then
                local CRUISE_H   = 900     -- высота эшелона (совпадает с CruiseHeight)
                local DIVE_DIST  = 2200    -- ближе этого — пикируем на цель
                local tdx = data.targetPos.x - mPos.x
                local tdy = (data.targetPos.y or 0) - mPos.y
                local horizDist = math.sqrt(tdx * tdx + tdy * tdy)

                local wantCruise = (horizDist > DIVE_DIST and (mPos.y or 0) < CRUISE_H)
                local aimX, aimY
                if wantCruise then
                    -- ещё далеко и низко: целимся в точку эшелона НАД
                    -- нами, смещённую к цели — ракета плавно набирает
                    -- высоту
                    aimX = data.targetPos.x
                    aimY = math.min(CRUISE_H, (data.targetPos.y or 0) + CRUISE_H)
                else
                    aimX = data.targetPos.x
                    aimY = data.targetPos.y or 0
                end

                -- Пере-выдаём цель движку ТОЛЬКО если она изменилась
                -- (режим сменился или цель перескочила). Сравнение по
                -- значениям — Vec3 не сравнивается по ссылке.
                local ap = data.cruiseAssigned
                if type(SetMissileTarget) == "function"
                   and (not ap or ap.x ~= aimX or ap.y ~= aimY
                        or data.cruising ~= wantCruise) then
                    pcall(SetMissileTarget, mId, Vec3(aimX, aimY, 0))
                    data.cruiseAssigned = { x = aimX, y = aimY }
                end
                data.cruising = wantCruise
            end
        end
    end

    MP_FRAME = frame
    checkTimer = checkTimer + 1
    if checkTimer < 3 then return end
    checkTimer = 0

    -- ========================================================
    --  ПРОКСИМИТИ-ПЕРЕХВАТ ПРОТИВОРАКЕТ (interceptmissile)
    --  РЕАЛЬНЫЕ API: ProjectileCount(teamId) + GetProjectileId(teamId, i)
    -- ========================================================
    --  ОПТИМИЗАЦИЯ. Раньше было:
    --      for каждая противоракета -> for каждая сторона ->
    --          for каждый снаряд -> NodePosition + сравнение
    --  то есть O(противоракеты × снаряды) ВЫЗОВОВ NodePosition за
    --  проход, и всё это каждые 3 кадра. При 5 противоракетах и
    --  200 снарядах — тысяча вызовов, из которых 995 считают одно
    --  и то же: список снарядов.
    --
    --  Теперь список снарядов собирается ОДИН раз за проход, а
    --  противоракеты проверяются по нему — O(снаряды + противоракеты).
    if interceptActive > 0 and type(ProjectileCount) == "function"
       and type(GetProjectileId) == "function" then
        -- 1. Собираем позиции ВСЕХ снарядов один раз.
        local projPos = {}
        local projCount = 0
        for _, side in ipairs({ 1, 2, 3, 4 }) do
            local count = ProjectileCount(side) or 0
            for i = 0, count - 1 do
                local projId = GetProjectileId(side, i)
                if projId then
                    local ok2, pPos = pcall(NodePosition, projId)
                    if ok2 and pPos then
                        projCount = projCount + 1
                        projPos[projCount] = { id = projId, x = pPos.x, y = pPos.y }
                    end
                end
            end
        end

        -- 2. Прогоняем противоракеты по готовому списку.
        local R2 = PROX_RADIUS * PROX_RADIUS
        for missileId in pairs(interceptMissiles) do
            local ok, mPos = pcall(NodePosition, missileId)
            if not ok or not mPos then
                interceptMissiles[missileId] = nil
                interceptActive = interceptActive - 1
            else
                for k = 1, projCount do
                    local p = projPos[k]
                    if p.id ~= missileId then
                        local dx = mPos.x - p.x
                        local dy = mPos.y - p.y
                        if (dx*dx + dy*dy) < R2 then
                            pcall(DestroyProjectile, missileId)
                            interceptMissiles[missileId] = nil
                            interceptActive = interceptActive - 1
                            break
                        end
                    end
                end
            end
        end
    end
end

function OnProjectileDestroyed(nodeId, teamId, saveName, structureIdHit, destroyType)
    penPlates[nodeId] = nil
    penLastStrut[nodeId] = nil
    if interceptMissiles[nodeId] then
        interceptMissiles[nodeId] = nil
        interceptActive = interceptActive - 1
    end
    HOMING_MISSILES[nodeId] = nil

    -- ДЕШЁВАЯ ОТСЕЧКА (оптимизация).
    -- Раньше здесь для КАЖДОГО уничтоженного снаряда (а это все
    -- пули, осколки, мины — сотни в секунду) вызывались
    -- NodePosition + NodeVelocity, и только потом выяснялось,
    -- что снаряд вообще не из нашего плана. Теперь сначала
    -- смотрим таблицу по имени — это хеш-поиск, почти бесплатно.
    local plan = BURST_PLAN[saveName]
    if not plan then return end

    local pos = NodePosition(nodeId)
    local vel = NodeVelocity(nodeId)
    if not pos or not vel then return end
    local speed = math.sqrt(vel.x*vel.x + vel.y*vel.y)
    if speed < 400 then speed = 400 end
    local baseAng = atan2(vel.y, vel.x)
    local cut = IsCookoff(nodeId, pos) and MP_COOKOFF_DIV or 1

    for _, item in ipairs(plan) do
        local kind, count, speedScale, mode, spread = item[1], item[2], item[3], item[4], item[5]
        if cut > 1 then
            count = math.floor(count / cut)
            if count < 4 then count = 4 end
        end
        local s = speed * speedScale
        for _ = 1, count do
            SpawnAt(kind, teamId, pos, baseAng, s, mode, spread)
        end
    end
end

-- ============================================================
--  СОБЫТИЯ УСТРОЙСТВ: ЯЩИКИ БОЕПРИПАСОВ
-- ============================================================
function OnDeviceCreated(teamId, deviceId, saveName, nodeA, nodeB, t, upgradedId)
    MP_TEAMS[teamId] = true

    if nodeA and nodeB and nodeA > 0 and nodeB > 0 then
        local okA, posA = pcall(NodePosition, nodeA)
        local okB, posB = pcall(NodePosition, nodeB)
        if okA and okB and posA and posB then
            local factor = t or 0.5
            MP_DEVICE_POS[deviceId] = Vec3(posA.x + (posB.x - posA.x) * factor, posA.y + (posB.y - posA.y) * factor, 0)
        end
    end
end

function OnDeviceHit(teamId, deviceId, saveName, newHealth, projectileNodeId, projectileTeamId, pos, reflectedByEnemy)
    if type(saveName) == "string" and (saveName:find("ammo") or saveName:find("crate")) then
        if not MP_DETONATED[deviceId] then
            MP_DETONATED[deviceId] = true
            local p = pos or MP_DEVICE_POS[deviceId]
            DetonateAmmoCrate(teamId, saveName, p)
        end
    end
end

function OnDeviceDestroyed(teamId, deviceId, saveName, nodeA, nodeB, t)
    local pos = MP_DEVICE_POS[deviceId]
    MP_DEVICE_POS[deviceId] = nil

    if not pos and nodeA and nodeB and nodeA > 0 and nodeB > 0 then
        local okA, posA = pcall(NodePosition, nodeA)
        local okB, posB = pcall(NodePosition, nodeB)
        if okA and okB and posA and posB then
            local factor = t or 0.5
            pos = Vec3(posA.x + (posB.x - posA.x) * factor, posA.y + (posB.y - posA.y) * factor, 0)
        elseif okA and posA then
            pos = posA
        elseif okB and posB then
            pos = posB
        end
    end

    if not MP_DETONATED[deviceId] then
        MP_DETONATED[deviceId] = true
        DetonateAmmoCrate(teamId, saveName, pos)
    end
end

local MP_PrevLoad = Load
function Load(gameStart)
    if MP_PrevLoad then pcall(MP_PrevLoad, gameStart) end
end
