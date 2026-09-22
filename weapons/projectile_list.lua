-- ============================================================
--  Military Pack: Список снарядов и боеприпасов (v22.0)
--  РАЗРЫВ СНАРЯДОВ — СТРУКТУРА КАК В РАБОЧЕМ АРХИВЕ (13)
--  Осколки = РЕАЛЬНЫЕ снаряды (cluster20mm / clusterpellet),
--  они сами вылетают из точки контакта и разлетаются.
--
--  v22.0 (по заказу):
--    * осколков В 2 РАЗА БОЛЬШЕ (особо у Тайфуна: 45 -> 90);
--    * жизнь осколков В 2 РАЗА ДОЛЬШЕ (8 -> 16 сек);
--    * снаряды и осколки живут ДО ЗЕМЛИ (без ExpiresOnFreeFall);
--    * ракета УМНЕЕ: CruiseHeight (свой эшелон), удержание цели,
--      приоритет по классу (реактор -> БК -> орудия).
-- ============================================================

local function FindProjectile(name)
    if type(Projectiles) ~= "table" then return nil end
    for _, p in ipairs(Projectiles) do
        if p.SaveName == name then return p end
    end
    return nil
end

local function FindAnyProjectile(...)
    for _, name in ipairs({...}) do
        local p = FindProjectile(name)
        if p then return p end
    end
    return nil
end

local function DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function Tune(p, hpMult, dmgMult, dpsMult)
    if type(p.MaxHitPoints) == "number" then p.MaxHitPoints = p.MaxHitPoints * hpMult end
    if type(p.Damage) == "number" then p.Damage = p.Damage * dmgMult end
    if type(p.DeviceDamageBonus) == "number" then p.DeviceDamageBonus = p.DeviceDamageBonus * dmgMult end
    if type(p.StructureDamageBonus) == "number" then p.StructureDamageBonus = p.StructureDamageBonus * dmgMult end
    if type(p.DeflectedDamageEnergy) == "number" then p.DeflectedDamageEnergy = p.DeflectedDamageEnergy * dmgMult end
    if type(p.DamagePerSecond) == "number" then p.DamagePerSecond = p.DamagePerSecond * dpsMult end
end

-- Поджог. ВАЖНО: IgnitePlatformOnDestruct — реальное поле движка,
-- именно оно даёт «100% поджог от каждого осколка».
local function SetFire(p, radius, radiusHeated)
    p.IncendiaryRadius       = radius or 60
    p.IncendiaryRadiusHeated = radiusHeated or ((radius or 60) * 1.5)
    p.IgnitePlatformOnDestruct = true
    p.DouseFires             = false
    p.ExtinguishesFire       = false
end

-- ============================================================
--  МЕХАНИЗМ РАЗРЫВА — КАК В РАБОЧЕМ АРХИВЕ (13)
-- ============================================================
--  В рабочем архиве разрыв описан ПРОСТОЙ таблицей прямо в
--  Effects, и всегда содержит четыре поля:
--
--      Projectile = { Count, Type, Speed, StdDev }
--      Effect     = "effects/mortar_air_burst.lua"
--      Splash     = true/false
--      Terminate  = true
--      Offset     = 0
--
--  Пример оттуда (флак-снаряд):
--      local boom = { Effect = "effects/mortar_air_burst.lua",
--                     Projectile = { Count = 30, Type = "mp_flak",
--                                    Speed = 1800, StdDev = 30 },
--                     Splash = false, Terminate = true }
--
--  И ТАМ ЖЕ, для разрыва в воздухе:
--      Age = AirburstAgeTable(airburst)   -- t1..t120
--
--  Про Offset: в архиве стоит Offset = 0. Это НЕ ломает осколки,
--  потому что осколок там — полноценный СНАРЯД (cluster20mm со
--  своей массой 16 и гравитацией), который сам вылетает из точки
--  контакта. Смещение -60/-120 нужно только для мелких пуль
--  (как shrapnel в weapon_pack), иначе они «рождаются в броне».
--
--  Наш прежний баг был НЕ в Offset, а в MinAge = 0.1: снаряд
--  умирал в первом же кадре, поэтому «при попадании нихуя нету».
local FRAG_SPAWN_OFFSET = 0 -- как в рабочем архиве

local FRAG_MATERIALS = {
    "device", "weapon", "antiair", "foundations", "rocks01", "shield",
    "armour", "heavyarmour", "armoureddoor", "backbracing", "bracing", "door",
}

-- Собрать таблицу разрыва по всем материалам (как PierceImpactTables
-- в рабочем архиве). pierceInto — материалы, которые снаряд
-- пробивает: там нет ни визуала, ни осколков, снаряд летит дальше.
local function MakeFragImpact(boomEffect, frag, pierceInto, splash, offset)
    local off = offset
    if off == nil then off = FRAG_SPAWN_OFFSET end

    local function entry()
        return {
            Effect     = boomEffect,
            Projectile = frag and DeepCopy(frag) or nil,
            Splash     = splash and true or false,
            Terminate  = true,
            Offset     = off,
        }
    end

    local t = {}
    for _, mat in ipairs(FRAG_MATERIALS) do
        t[mat] = entry()
    end
    t["default"] = entry()

    local pierce = { Effect = nil, Splash = false, Terminate = false, KeepHitpointLoss = true }
    for _, name in ipairs(pierceInto or {}) do
        t[name] = pierce
    end
    return t
end

-- ============================================================
--  ОСКОЛКИ — РЕАЛЬНЫЕ СНАРЯДЫ (как в рабочем архиве)
-- ============================================================
--  В архиве осколками были НЕ абстрактные «частицы», а копии
--  настоящих снарядов игры:
--      cluster20mm   = копия cannon20mm   (mass 16, drag 0)
--      clusterpellet = копия machinegun   (пуля)
--  Поэтому осколки летели, рикошетили и поджигали — как надо.
-- ВНИМАНИЕ: счётчики УДВОЕНЫ по требованию заказчика
-- («у всех пушек много их в 2 раза увеличь осколки»).
-- Было: 18 / 32 / 14 / 24 / 20. Стало: 36 / 64 / 28 / 48 / 40.
--
-- ЗАКАЗЧИК #2: «сделай больше осколков». Ещё +50% к текущим
-- (36->54, 64->96, 28->42, 48->72, 40->60).
--
-- ВАЖНО: это БЕЗОПАСНО, потому что теперь в script.lua стоит
-- глобальный лимит снарядов (MP_PROJ_LIMIT = 1000) — при
-- переполнении всё чистится под ноль. То есть даже если один
-- залп родит больше осколков, чем движок переваривает, игра не
-- упадёт, а сбросит лишнее.
local FRAG_HEAVY  = { Count = 54, Type = "cluster20mm",   Speed = 2000, StdDev = 30 }
local FRAG_BIG    = { Count = 96, Type = "cluster20mm",   Speed = 2200, StdDev = 25 }
local FRAG_PELLET = { Count = 42, Type = "clusterpellet", Speed = 2600, StdDev = 35 }
local FRAG_MIXED  = { Count = 72, Type = "cluster20mm",   Speed = 2100, StdDev = 28 }
local FRAG_SHOT   = { Count = 60, Type = "shotgun",       Speed = 2200, StdDev = 25 }

-- ============================================================
--  СРОК ЖИЗНИ ОСКОЛКОВ — ДО ЗЕМЛИ
-- ============================================================
--  ИСТОРИЯ БАГОВ (важно не наступить снова):
--    1) Сначала у осколков не было НИЧЕГО — жили вечно.
--    2) Потом MinAge = 0.1 — умирали в первом кадре,
--       отсюда «при попадании нихуя нету».
--
--  MinAge — это НЕ «минимальный срок жизни», а минимальный
--  возраст, с которого начинают работать триггеры Age.
--  Ставить 0.1 нельзя. Весь срок задаётся полем MaxAge.
--
--  Эталон живучести в игре: machinegun — MinAge = 2.5, MaxAge = 20.
--
--  ЗАКАЗЧИК: «сделай в 2 раза больше жизнь осколков» и
--  «сделай чтобы жили до земли». Поэтому:
--    * FRAG_MAX_AGE удвоен (8 -> 16 сек);
--    * ExpiresOnFreeFall НЕ ставим — осколок не гаснет, потеряв
--      скорость (иначе он замирает в воздухе и исчезает);
--    * у осколка НЕТ DetonatesOnExpiry — он не рвётся в воздухе,
--      а просто летит и падает на землю/в цель.
--  16 секунд при скорости 2000-2600 ед/с — это дистанция порядка
--  30 тысяч единиц, то есть карта целиком. Осколок живёт ровно
--  столько, сколько нужно, чтобы долететь до земли.
local FRAG_MAX_AGE = 16.0 -- сек (было 8.0)

local function MakeFragment(p, maxAge, drag, gravity, mass)
    p.MinAge            = 0.5
    p.MaxAge            = maxAge or FRAG_MAX_AGE
    p.ExpiresOnFreeFall = nil   -- не гаснуть, потеряв скорость
    p.LifeSpan          = nil   -- такого поля в движке НЕТ
    -- Осколок падает на землю САМ, а не рвётся в воздухе по сроку.
    p.DetonatesOnExpiry  = false
    p.AgeEffectsOnExpiry = false
    if drag    then p.ProjectileDrag = drag end
    if gravity then p.Gravity = gravity end
    if mass    then p.ProjectileMass = mass end
    p.KeepAge      = nil
    p.KeepLifespan = nil
    p.DrawFromAge  = nil
    return p
end

-- ============================================================
--  РАЗРЫВ В ВОЗДУХЕ (airburst)
-- ============================================================
--  РЕАЛЬНЫЙ механизм в движке (проверено по Forts.exe):
--      Effects.Age               — таблица ИМЕНОВАННЫХ действий
--      TriggerProjectileAgeAction — оружие запускает это действие
--      MinAgeTrigger / MaxAgeTrigger — окно срабатывания (СЕКУНДЫ)
--      DetonatesOnExpiry / AgeEffectsOnExpiry — рвать по сроку
--
--  Ключ внутри Age — это ПРОСТО МЕТКА, а не тик и не секунда.
--  Прежний код верил, что t8 = «8 тиков», и ракета рвалась у дула.
--
--  Эталон в игре — мод weapon_pack:
--      projectile:  Age = { t200 = FlakDetonation }
--      оружие flak: TriggerProjectileAgeAction = true
--                   MinAgeTrigger = 0.3, MaxAgeTrigger = 1.1
local AIRBURST_KEY = "burst"

local function Airburst(frag, splash)
    return {
        Effect     = "effects/mortar_air_burst.lua",
        Projectile = frag and DeepCopy(frag) or nil,
        Terminate  = true,
        Splash     = splash and true or false,
    }
end

-- Включить воздушный разрыв по времени жизни снаряда.
--   airTime — сколько СЕКУНД снаряд живёт до разрыва в воздухе
local function SetAirburst(p, airTime, frag, splash)
    p.MaxAge             = airTime
    p.DetonatesOnExpiry  = true
    p.AgeEffectsOnExpiry = true
    p.Effects            = p.Effects or {}
    p.Effects.Age        = { [AIRBURST_KEY] = Airburst(frag, splash) }
    return p
end

-- Предохранитель ракет: минимум СЕКУНД полёта до разрыва.
-- «Увеличь дальность жизни снарядов типо ракеты управляемой» —
-- ракета должна успеть долететь до цели на другом конце карты,
-- поэтому предохранитель поднят (4 -> 10 сек).
local ROCKET_AIR_TIME = 10.0
-- Артиллерия рвётся в воздухе заранее, если ни во что не попала.
-- Тоже удвоено (6 -> 12 сек): снаряд живёт до земли.
local SHELL_AIR_TIME  = 12.0

-- ============================================================
--  1. ОСКОЛКИ-СНАРЯДЫ (базис всего разрыва)
-- ============================================================

-- 1a. Тяжёлый 20мм осколок (cluster20mm) — ЗАЖИГАТЕЛЬНЫЙ
--     Копия настоящего cannon20mm из weapon_pack: mass 16, drag 0.
--     ВАЖНО: fallback на "cannon" — cannon20mm есть только когда
--     подключён weapon_pack, иначе берём обычную пушку.
local fHeavyBase = FindAnyProjectile("cannon20mm", "cannon")
if fHeavyBase then
    local s = DeepCopy(fHeavyBase)
    s.SaveName = "cluster20mm"
    Tune(s, 0.9, 0.9, 0.9)
    SetFire(s, 80, 120)
    s.Gravity        = 900
    s.ProjectileDrag = 0.12
    MakeFragment(s, FRAG_MAX_AGE)
    s.ExpiresOnFreeFall = false  -- именно так долетает до земли
    -- Терминальный осколок: своих осколков НЕ даёт (иначе рекурсия),
    -- поэтому Impact = только визуал.
    s.Effects = s.Effects or {}
    s.Effects.Impact = {
        ["default"] = { Effect = "effects/mortar_air_burst.lua", Splash = false, Terminate = true },
    }
    s.Effects.Age = nil
    s.DetonatesOnExpiry  = false
    s.AgeEffectsOnExpiry = false
    table.insert(Projectiles, s)
end

-- 1b. Картечь 20мм (clusterpellet) — ЗАЖИГАТЕЛЬНАЯ
--     Копия настоящей пули machinegun (как в рабочем архиве).
local pelletBase = FindAnyProjectile("machinegun", "cluster20mm")
if pelletBase then
    local s = DeepCopy(pelletBase)
    s.SaveName = "clusterpellet"
    s.Gravity          = 1000
    s.ProjectileDrag   = 2.0
    s.ProjectileMass   = 16
    s.DrawBlurredProjectile = true
    Tune(s, 0.6, 1.0, 1.0)
    SetFire(s, 60, 90)
    MakeFragment(s, 10.0)
    s.ExpiresOnFreeFall = false
    s.Effects = s.Effects or {}
    s.Effects.Impact = {
        ["default"] = { Effect = "effects/mortar_air_burst.lua", Splash = false, Terminate = true },
    }
    s.Effects.Age = nil
    s.DetonatesOnExpiry  = false
    s.AgeEffectsOnExpiry = false
    table.insert(Projectiles, s)
end

-- 1c. Зажигательная пуля Military Pack (mp_bullet)
local bulletBase = FindAnyProjectile("machinegun", "sniper")
if bulletBase then
    local s = DeepCopy(bulletBase)
    s.SaveName = "mp_bullet"
    s.Damage                = 18
    s.DeviceDamageBonus     = 22
    s.StructureDamageBonus  = 18
    s.DeflectedDamageEnergy = 20
    SetFire(s, 50, 75)
    s.Gravity        = 800
    s.ProjectileDrag = 0.05
    MakeFragment(s, 8.0)
    s.ExpiresOnFreeFall = false
    s.Effects = s.Effects or {}
    s.Effects.Impact = {
        ["default"] = { Effect = "effects/impact_light.lua", Splash = false, Terminate = true },
    }
    s.Effects.Age = nil
    s.DetonatesOnExpiry  = false
    s.AgeEffectsOnExpiry = false
    table.insert(Projectiles, s)
end

-- 1d. Зенитный осколок (mp_flak) — ЧИСТОЕ ПВО, 0 урона по постройкам
--     Копия flak из weapon_pack (меньше — machinegun).
local flakBase = FindAnyProjectile("flak", "machinegun")
if flakBase then
    local s = DeepCopy(flakBase)
    s.SaveName = "mp_flak"
    s.ProjectileDamage                = 0.0
    s.ProjectileSplashDamage          = 0.0
    s.ProjectileSplashDamageMaxRadius = 0.0
    s.IncendiaryRadius                = 0.0
    s.IncendiaryRadiusHeated          = 0.0
    s.IgnitePlatformOnDestruct        = false
    s.DamageMultiplier =
    {
        { SaveName = "armour",          Direct = 0, Splash = 0 },
        { SaveName = "bracing",         Direct = 0, Splash = 0 },
        { SaveName = "backbracing",     Direct = 0, Splash = 0 },
        { SaveName = "door",            Direct = 0, Splash = 0 },
        { SaveName = "heavyarmour",     Direct = 0, Splash = 0 },
        { SaveName = "armoureddoor",    Direct = 0, Splash = 0 },
        { SaveName = "shield",          Direct = 0, Splash = 0 },
        { SaveName = "foundations",     Direct = 0, Splash = 0 },
        { SaveName = "rocks01",         Direct = 0, Splash = 0 },
        { SaveName = "device",          Direct = 0, Splash = 0 },
        { SaveName = "weapon",          Direct = 0, Splash = 0 },
    }
    s.Gravity        = 600
    s.ProjectileDrag = 0.1
    MakeFragment(s, 12.0)
    s.ExpiresOnFreeFall = false
    s.Effects = s.Effects or {}
    s.Effects.Impact = {
        ["default"] = { Effect = "effects/mortar_air_burst.lua", Splash = false, Terminate = true },
    }
    s.Effects.Age = nil
    s.DetonatesOnExpiry  = false
    s.AgeEffectsOnExpiry = false
    table.insert(Projectiles, s)
end

-- ============================================================
--  2. КАССЕТНЫЕ СНАРЯДЫ (главный разрыв «как в архиве»)
-- ============================================================

-- 2a. Кассета-носитель T1 (clustershell)
local carrierBase = FindAnyProjectile("mortar", "cannon")
if carrierBase then
    local s = DeepCopy(carrierBase)
    s.SaveName = "clustershell"
    Tune(s, 1.25, 0.70, 0.60)
    SetFire(s, 100, 150)
    s.ProjectileDrag = 0.4
    s.Gravity        = 1000
    s.CanBeShotDown  = true
    -- РАЗРЫВ: 24 тяжёлых 20мм осколка
    s.Effects = s.Effects or {}
    s.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_MIXED,
                                      { "bracing", "door", "armour", "armoureddoor" }, true)
    SetAirburst(s, SHELL_AIR_TIME, FRAG_MIXED, true)
    table.insert(Projectiles, s)

    -- 2b. Кассета-носитель T2 (clustershell2)
    local s2 = DeepCopy(carrierBase)
    s2.SaveName = "clustershell2"
    Tune(s2, 1.8, 0.85, 0.75)
    SetFire(s2, 140, 200)
    s2.ProjectileDrag = 0.35
    s2.Gravity        = 900
    s2.CanBeShotDown  = true
    s2.Effects = s2.Effects or {}
    s2.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_BIG,
                                       { "bracing", "door", "armour", "armoureddoor" }, true)
    SetAirburst(s2, SHELL_AIR_TIME, FRAG_BIG, true)
    table.insert(Projectiles, s2)

    -- 2c. Кумулятивный T1 (heat_shell)
    local s3 = DeepCopy(carrierBase)
    s3.SaveName = "heat_shell"
    Tune(s3, 1.3, 0.75, 0.65)
    SetFire(s3, 110, 160)
    s3.ProjectileDrag = 0.4
    s3.Gravity        = 1000
    s3.Effects = s3.Effects or {}
    s3.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_HEAVY,
                                       { "bracing", "door" }, true)
    SetAirburst(s3, SHELL_AIR_TIME, FRAG_HEAVY, true)
    table.insert(Projectiles, s3)

    -- 2d. Кумулятивный T2 (heat_shell2)
    local s4 = DeepCopy(carrierBase)
    s4.SaveName = "heat_shell2"
    Tune(s4, 1.9, 0.90, 0.80)
    SetFire(s4, 150, 220)
    s4.ProjectileDrag = 0.35
    s4.Gravity        = 900
    s4.Effects = s4.Effects or {}
    s4.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_BIG,
                                       { "bracing", "door" }, true)
    SetAirburst(s4, SHELL_AIR_TIME, FRAG_BIG, true)
    table.insert(Projectiles, s4)

    -- 2e. Бронебойный T1 (ap_shell)
    local s5 = DeepCopy(carrierBase)
    s5.SaveName = "ap_shell"
    Tune(s5, 1.4, 0.80, 0.70)
    SetFire(s5, 120, 170)
    s5.ProjectileDrag = 0.35
    s5.Gravity        = 950
    s5.Effects = s5.Effects or {}
    s5.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_HEAVY,
                                       { "bracing", "door", "armour", "armoureddoor" }, true)
    SetAirburst(s5, SHELL_AIR_TIME, FRAG_HEAVY, true)
    table.insert(Projectiles, s5)

    -- 2f. Бронебойный T2 (ap_shell2)
    local s6 = DeepCopy(carrierBase)
    s6.SaveName = "ap_shell2"
    Tune(s6, 2.0, 0.95, 0.85)
    SetFire(s6, 160, 230)
    s6.ProjectileDrag = 0.3
    s6.Gravity        = 850
    s6.Effects = s6.Effects or {}
    s6.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_BIG,
                                       { "bracing", "door", "armour", "armoureddoor" }, true)
    SetAirburst(s6, SHELL_AIR_TIME, FRAG_BIG, true)
    table.insert(Projectiles, s6)
end

-- ============================================================
--  3. РАКЕТЫ
-- ============================================================

-- 3a. Зенитная ракета ПЗРК (aarocket) — неуправляемая
local rocketBase = FindAnyProjectile("rocket", "rocketemp")
if rocketBase then
    local s = DeepCopy(rocketBase)
    s.SaveName = "aarocket"
    Tune(s, 0.80, 0.60, 0.50)
    SetFire(s, 90, 130)
    s.ProjectileDrag = 0.3
    s.Gravity        = 1200
    s.Effects = s.Effects or {}
    s.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_PELLET, nil, true)
    SetAirburst(s, ROCKET_AIR_TIME, FRAG_PELLET, true)
    table.insert(Projectiles, s)

    -- 3b. ЗРК (aamissile) — неуправляемая
    local s2 = DeepCopy(rocketBase)
    s2.SaveName = "aamissile"
    Tune(s2, 1.5, 1.2, 1.0)
    SetFire(s2, 110, 150)
    s2.ProjectileDrag = 0.3
    s2.Gravity        = 1700
    s2.Effects = s2.Effects or {}
    s2.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_PELLET, nil, true)
    SetAirburst(s2, ROCKET_AIR_TIME, FRAG_PELLET, true)
    table.insert(Projectiles, s2)

    -- ========================================================
    --  ЗРК: СНАРЯДЫ С РАЗНЫМ РАДИУСОМ РАЗРЫВА
    -- ========================================================
    --  Игрок выбирает радиус разрыва ПЕРЕД выстрелом, как зениткой
    --  (dlc2_Ammunition в zrk.lua). Радиус задаётся АБСОЛЮТНО:
    --      ProjectileSplashDamage          — урон по площади
    --      ProjectileSplashDamageMaxRadius — радиус площади
    --  Множитель от базовых 100 ед. давал бесполезные 70-190.
    --  Осколков по тирам: было 16/24/36/48, удвоено -> 32/48/72/96,
    --  затем +50% по просьбе заказчика -> 48/72/96/120.
    --
    --  ВАЖНО про лимит: теперь в script.lua есть MP_PROJ_LIMIT = 1000,
    --  и топовый тир r4 (120 у ЗРК-снаряда) в сумме с наложением
    --  залпа может упереться в лимит. Это ОЖИДАЕМО: переполнение
    --  теперь не роняет игру, а чистит поле. Поэтому цифры можно
    --  держать смелыми.
    local zrkTiers =
    {
        -- имя              радиус  урон  осколков
        { "aamissile_r1",   220,  40, 48 },  -- узкий: точечный удар
        { "aamissile_r2",   340,  60, 72 },  -- средний
        { "aamissile_r3",   480,  85, 96 },  -- широкий: накрывает строй
        { "aamissile_r4",   650, 120, 120 }, -- максимальный
    }
    for _, tier in ipairs(zrkTiers) do
        local name, radius, dmg, cnt = tier[1], tier[2], tier[3], tier[4]
        local v = DeepCopy(s2)
        v.SaveName = name
        v.ProjectileSplashDamage          = dmg
        v.ProjectileSplashDamageMaxRadius = radius
        local frag = { Count = cnt, Type = "mp_flak", Speed = 2400, StdDev = 30 }
        v.Effects = v.Effects or {}
        v.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", frag, nil, true)
        SetAirburst(v, ROCKET_AIR_TIME, frag, true)
        table.insert(Projectiles, v)
    end
end

-- ============================================================
--  4. ГСН-РАКЕТА (homingrocket) — САМОНАВОДЯЩАЯСЯ
-- ============================================================
--  ЗАХВАТ ЦЕЛИ обеспечивает ДВИЖОК через SetMissileTarget.
--  Блок Missile даёт ТОЛЬКО тягу и поворот, он НЕ выбирает цель.
--  Скрипт (script.lua) находит цель и назначает её движку.
--
--  РЕАЛЬНЫЕ поля наведения (проверено по Forts.exe):
--    ThrustAngleExtent, ErraticAngleExtentStdDev, ErraticAngleExtentMax,
--    MaxSteerPerSecond, MaxSteerPerSecondErratic, ErraticThrust,
--    LaunchThrust, RocketThrust, CruiseTargetDistance,
--    CruiseTargetDuration, TargetRearOffsetDistance,
--    MinTargetUpdateDistance, DecoyFramesToRedirect
--
--  Эталон в игре — weapon_pack/rocketemp:
--    MaxSteerPerSecond = 200 при массе 5.0 (~2G),
--    RocketThrust = 10000, ErraticThrust = 1.4
-- ============================================================
local empBase = FindProjectile("rocketemp") or FindProjectile("rocket")
if empBase then
    local s = DeepCopy(empBase)
    s.SaveName = "homingrocket"
    s.ProjectileType = "missile"
    Tune(s, 2.0, 1.8, 1.6)
    SetFire(s, 140, 200)

    -- Физика полёта (реальные поля Forts)
    s.Gravity                     = 0
    s.ProjectileShootDownRadius   = 15
    s.CanBeShotDown               = true
    s.ProjectileMass              = 5.0
    -- Быстрее, чем было (45 -> 18): меньше тормозит на марше.
    s.ProjectileDrag              = 18

    -- Чужие поля — в Forts их НЕТ, они ничего не делают.
    s.MaxSpeed                 = nil
    s.Acceleration             = nil
    s.Thrust                   = nil
    s.MaxTurnRate              = nil
    s.SeekRadius               = nil
    s.TrackingDistance         = nil
    s.LifeSpan                 = nil
    s.FieldRadius              = nil

    -- ========================================================
    --  РАКЕТА: БЫСТРАЯ + ПЕРЕГРУЗКА ~15G + БЕЗ ДЁРГАНЬЯ
    -- ========================================================
    --  «Её трепит» — это хаотичная тяга и слишком резкий
    --  MaxSteerPerSecond. У эталона missile2 доворот 150°/с при
    --  массе 5.0 (~2G). Для ~15G нужно примерно в 7.5 раза резче.
    --
    --  Но если ОДНОВРЕМЕННО держать максимум доворота И максимум
    --  Erratic, рули перебирают и ракету трясёт, поэтому
    --  «дёрганье» гасим тремя способами:
    --    1) ErraticAngleExtent* -> почти в ноль (рули не шумят);
    --    2) ErraticThrust        -> почти в ноль (тяга ровная);
    --    3) ThrustAngleExtent    -> меньше, тяга бьёт точнее в цель.
    --  Скорость поднимаем через RocketThrust + низкий drag.
    --
    --  «Сделай её умней» — за это отвечают поля ниже:
    --    * CruiseHeight          — РЕАЛЬНОЕ поле движка (проверено по
    --      Forts.exe: строка формата "CruiseHeight %.9g"). Задаёт
    --      ВЫСОТУ крейсерского эшелона: ракета сама выходит на эту
    --      высоту и идёт по ней, то есть перелетает свои холмы и
    --      чужие стены, а не бьётся в них. Это и есть «умный» полёт.
    --    * CruiseTargetDistance  — дистанция крейсера до цели
    --      (когда до цели ближе — ракета переходит в пикирование).
    --    * MinTargetUpdateDistance — пере-прицеливание: чем меньше,
    --      тем чаще движок доворачивает на сместившуюся цель.
    --      400 -> 250 (цель не «убегает»).
    --    * DecoyFramesToRedirect = 2 — ракета почти не отвлекается
    --      на ловушки (при 1 она бы реагировала на каждый чих,
    --      при 3+ игнорирует реальные смещения цели).
    s.Missile =
    {
        ThrustAngleExtent          = 45,     -- уже веер тяги = меньше рыскания
        ErraticAngleExtentStdDev   = 0.02,   -- почти без шума рулей
        ErraticAngleExtentMax      = 0.05,   -- «дергается» -> убрано
        MaxSteerPerSecond          = 1150,   -- ~15G
        MaxSteerPerSecondErratic   = 1180,   -- почти не выше базового
        ErraticAnglePeriodMean     = 1.5,    -- шум медленный, а не дрожь
        ErraticAnglePeriodStdDev   = 0.2,
        ErraticThrust              = 0.02,   -- ровная тяга
        ErraticThrustMagneticField = 0.05,
        LaunchThrust               = 30000,  -- уверенный выход из трубы
        RocketThrust               = 62000,  -- маршевая: ЗАМЕТНО быстрее
        RocketThrustChange         = 12000,
        CruiseHeight               = 900,    -- УМНЫЙ ПОЛЁТ: свой эшелон
        CruiseTargetDistance       = 2600,   -- высотный эшелон (было 1800)
        CruiseTargetDuration       = 1.0,
        TargetRearOffsetDistance   = 100000,
        MinTargetUpdateDistance    = 250,    -- чаще обновляет прицел
        DecoyFramesToRedirect      = 2,
    }

    -- ========================================================
    --  ОСКОЛКИ ГСН-РАКЕТЫ
    --  Движок сам спавнит их при попадании через Effects.Impact.
    --  ВОЗДУШНОГО РАЗРЫВА НЕТ СОЗНАТЕЛЬНО: ракета рвётся ТОЛЬКО
    --  при попадании в цель (так требовал заказчик).
    --  Осколков: 28 -> 56 -> 84 (+50%), живут ДО ЗЕМЛИ.
    -- ========================================================
    s.Effects = s.Effects or {}
    s.Effects.Impact = MakeFragImpact(
        "effects/mortar_air_burst.lua",
        { Count = 84, Type = "cluster20mm", Speed = 2200, StdDev = 28 },
        { "bracing", "door", "armour", "armoureddoor" },
        true)
    s.Effects.Age        = nil
    s.DetonatesOnExpiry  = false
    s.AgeEffectsOnExpiry = false
    -- Ракета живёт ДО ЗЕМЛИ, а не самоуничтожается через 12 сек:
    -- при 12 секундах она не успевала дойти до дальних баз.
    s.MaxAge = 30.0
    s.ExpiresOnFreeFall = false
    table.insert(Projectiles, s)
end

-- ============================================================
--  5. ПРОЧЕЕ
-- ============================================================

-- 5a. ЭМИ-ракета ПЗРК (emprocket)
local empBase2 = FindAnyProjectile("rocketemp", "rocket")
if empBase2 then
    local s = DeepCopy(empBase2)
    s.SaveName = "emprocket"
    Tune(s, 1.2, 1.2, 1.2)
    SetFire(s, 120, 160)
    s.ProjectileDrag = 0.3
    s.Gravity        = 1300
    s.Effects = s.Effects or {}
    s.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_PELLET, nil, true)
    SetAirburst(s, ROCKET_AIR_TIME, FRAG_PELLET, true)
    table.insert(Projectiles, s)
end

-- 5b. Зенитный снаряд Flak (flakshell) — ПВО
local flakGunBase = FindAnyProjectile("flak", "machinegun")
if flakGunBase then
    local s = DeepCopy(flakGunBase)
    s.SaveName = "flakshell"
    Tune(s, 1.3, 0.60, 0.60)
    SetFire(s, 100, 140)
    s.ProjectileDrag = 0.15
    s.Gravity        = 700
    s.Effects = s.Effects or {}
    -- Осколков: 20 -> 40 -> 60 (+50%)
    s.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua",
                                      { Count = 60, Type = "mp_flak", Speed = 2400, StdDev = 30 },
                                      nil, true)
    SetAirburst(s, SHELL_AIR_TIME, { Count = 60, Type = "mp_flak", Speed = 2400, StdDev = 30 }, true)
    table.insert(Projectiles, s)
end

-- 5c. Шрапнельный снаряд 20мм (shrapnelshell)
if flakGunBase then
    local s = DeepCopy(flakGunBase)
    s.SaveName = "shrapnelshell"
    Tune(s, 1.2, 0.55, 0.55)
    SetFire(s, 90, 130)
    s.ProjectileDrag = 0.2
    s.Gravity        = 800
    s.Effects = s.Effects or {}
    s.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua", FRAG_SHOT,
                                      { "bracing", "door" }, true)
    SetAirburst(s, SHELL_AIR_TIME, FRAG_SHOT, true)
    table.insert(Projectiles, s)
end

-- 5d. Противоракета ПРО (interceptmissile)
--     ВАЖНО: раньше здесь искался снаряд с именем "swarm" — такого
--     снаряда в игре НЕТ, поэтому ветка молча не собиралась и
--     противоракеты не существовало. Fallback оставлен на реальные
--     ракетные снаряды.
local swarmBase = FindAnyProjectile("missile", "missile2", "rocketemp", "rocket")
if swarmBase then
    local s = DeepCopy(swarmBase)
    s.SaveName = "interceptmissile"
    s.ProjectileType = "missile"

    s.MaxTurnRate      = nil
    s.MaxSpeed         = nil
    s.Acceleration     = nil
    s.Thrust           = nil
    s.LifeSpan         = nil
    s.SeekRadius       = nil
    s.TrackingDistance = nil

    s.Gravity        = 0
    s.ProjectileDrag = 24
    s.ProjectileMass = 3.0
    Tune(s, 1.5, 0.80, 0.80)
    SetFire(s, 100, 140)

    -- Противоракете нужен настоящий блок Missile, иначе
    -- ProjectileType = "missile" не даёт ничего.
    s.Missile =
    {
        ThrustAngleExtent          = 45,
        ErraticAngleExtentStdDev   = 0.05,
        ErraticAngleExtentMax      = 0.1,
        MaxSteerPerSecond          = 1200,  -- ~15G: догоняет манёвренную цель
        MaxSteerPerSecondErratic   = 1240,
        ErraticAnglePeriodMean     = 1.2,
        ErraticAnglePeriodStdDev   = 0.2,
        ErraticThrust              = 0.03,
        ErraticThrustMagneticField = 0.06,
        LaunchThrust               = 24000,
        RocketThrust               = 48000,
        CruiseHeight               = 700,    -- держит высоту, ищет цель
        CruiseTargetDistance       = 1600,
        CruiseTargetDuration       = 0.8,
        TargetRearOffsetDistance   = 100000,
        MinTargetUpdateDistance    = 350,    -- ПРО доворачивает быстрее
        DecoyFramesToRedirect      = 1,      -- ПРО почти не обмануть ловушками
    }

    s.Effects = s.Effects or {}
    -- Осколков: 24 -> 48 -> 72 (+50%)
    s.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua",
                                      { Count = 72, Type = "mp_flak", Speed = 2600, StdDev = 30 },
                                      nil, true)
    SetAirburst(s, ROCKET_AIR_TIME, { Count = 72, Type = "mp_flak", Speed = 2600, StdDev = 30 }, true)
    table.insert(Projectiles, s)
end

-- 5e. Сверхтяжёлый снаряд Тайфун (typhoonshell)
local heavyBase = FindAnyProjectile("howitzer", "cannon2", "cannon")
if heavyBase then
    local s = DeepCopy(heavyBase)
    s.SaveName = "typhoonshell"
    Tune(s, 3.5, 2.0, 2.0)
    SetFire(s, 250, 350)
    s.ProjectileDrag = 0.25
    s.Gravity        = 800
    s.CanBeShotDown  = true
    s.Effects = s.Effects or {}
    -- ТАЙФУН: осколков 45 -> 90 -> 135 (+50%), как просил заказчик
    -- («особо у тайфуна»). Это самый мощный разрыв в моде.
    s.Effects.Impact = MakeFragImpact("effects/mortar_air_burst.lua",
                                      { Count = 135, Type = "cluster20mm", Speed = 2300, StdDev = 22 },
                                      { "bracing", "door", "armour", "armoureddoor" }, true)
    SetAirburst(s, SHELL_AIR_TIME, { Count = 135, Type = "cluster20mm", Speed = 2300, StdDev = 22 }, true)
    -- Живёт до земли: 12 секунд и никакого гасения по потере скорости.
    s.ExpiresOnFreeFall = false
    table.insert(Projectiles, s)
end

-- ============================================================
--  6. УСИЛЕННЫЕ ВАРИАНТЫ М2 (как в рабочем архиве)
-- ============================================================
--  Это копии базовых снарядов T1 с УДВОЕННЫМ разрывом: копия
--  наследует Impact от источника (напр. clustershell = FRAG_MIXED),
--  а своя копия осколка получает Count x2. Так «усиленный вариант»
--  реально сильнее базового, а не просто дубликат (как было раньше).
--
--  ВАЖНО про лимит снарядов (проверено замером реальных таблиц):
--  в Effects лежит ПО ОДНОЙ ветке на материал (default/foundations/
--  weapon/...), и срабатывает РОВНО ОДНА — та, во что попали.
--  Поэтому размер разрыва = Count ОДНОЙ ветки, а не их сумма.
--  Реальные максимумы мода: clustershell2x = 144, typhoonshell = 135,
--  aamissile_r4 = 120. Это в разы ниже MP_PROJ_LIMIT (1000), так что
--  один выстрел лимит не пробивает — лимит ловит только НАКОПЛЕНИЕ
--  (несколько залпов + осколки + подрыв ящиков одновременно).
local M2_FRAG_MULT = 2

local function DoubleFragCounts(p)
    if type(p.Effects) ~= "table" then return end
    for _, tbl in pairs(p.Effects) do
        if type(tbl) == "table" then
            for _, e in pairs(tbl) do
                if type(e) == "table" and type(e.Projectile) == "table"
                   and type(e.Projectile.Count) == "number" then
                    e.Projectile.Count = math.floor(e.Projectile.Count * M2_FRAG_MULT)
                end
            end
        end
    end
end

for _, pair in ipairs(
    {
        { "clustershell", "clustershell2x" },
        { "heat_shell",   "heat_shell2x"   },
        { "ap_shell",     "ap_shell2x"     },
    }) do
    local srcP = FindProjectile(pair[1])
    if srcP then
        local c = DeepCopy(srcP)
        c.SaveName = pair[2]
        SetFire(c, 110, 150)
        DoubleFragCounts(c)   -- усиленный = x2 осколков
        table.insert(Projectiles, c)
    end
end
