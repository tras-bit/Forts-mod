-- ============================================================
--  Military Pack: устройства — device_list.lua (v4.6)
-- ============================================================

dofile("ui/uihelper.lua")
dofile("scripts/type.lua")

-- HUD: кнопки и карточка Военного завода
table.insert(Sprites, DetailSprite("hud-detail-mpfactory", "HUD-Details-Factory", path))
table.insert(Sprites, ButtonSprite("hud-mpfactory-icon", "HUD/HUD-Factory", nil, ButtonSpriteBottom, nil, nil, path))

-- Иконки ванильных шахт (новые текстуры 640x310)
table.insert(Sprites, DetailSprite("hud-detail-mpmine", "HUD-Details-MpMine", path))
table.insert(Sprites, ButtonSprite("hud-mpmine-icon", "HUD/HUD-MpMine", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, DetailSprite("hud-detail-mpmine2", "HUD-Details-MpMine2", path))
table.insert(Sprites, ButtonSprite("hud-mpmine2-icon", "HUD/HUD-MpMine2", nil, ButtonSpriteBottom, nil, nil, path))

-- Иконки ветряков (1 уровень и 2 уровень супер-турбина)
table.insert(Sprites, DetailSprite("hud-detail-mpwindmill", "HUD-Details-MpWindmill", path))
table.insert(Sprites, ButtonSprite("hud-mpwindmill-icon", "HUD/HUD-MpWindmill", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, DetailSprite("hud-detail-mpwindmill2", "HUD-Details-MpWindmill2", path))
table.insert(Sprites, ButtonSprite("hud-mpwindmill2-icon", "HUD/HUD-MpWindmill2", nil, ButtonSpriteBottom, nil, nil, path))

if Devices == nil then
    Devices = {}
end

-- ============================================================
--  ЦЕПОЧКА ТЕХНОЛОГИЙ: Мастерская -> Арсенал -> Военный завод
-- ============================================================

-- 1. Мастерская активна, строится свободно
local workshop = FindDevice("workshop")
if workshop then
    workshop.Prerequisite = nil
    workshop.Enabled = true
end

-- 2. Арсенал активен, требует Мастерскую
local armoury = FindDevice("armoury")
if armoury then
    armoury.Prerequisite = "workshop"
    armoury.Enabled = true
end

-- 3. Военный завод (mpfactory): наследуется от технологии (InheritType),
--    помещается в категорию ТЕХНОЛОГИИ, требует Арсенал, строится 60 с
local techBase = FindDevice("factory") or FindDevice("munitions") or FindDevice("armoury") or FindDevice("workshop")
local insertIdx = IndexOfDevice("armoury") or IndexOfDevice("munitions") or IndexOfDevice("workshop") or #Devices

if techBase and insertIdx then
    table.insert(Devices, insertIdx + 1,
        InheritType(techBase, nil,
        {
            SaveName              = "mpfactory",
            FileName              = path .. "/devices/mpfactory.lua",
            Icon                  = "hud-mpfactory-icon",
            Detail                = "hud-detail-mpfactory",
            Enabled               = true,
            Prerequisite          = "armoury", -- цепочка: Мастерская -> Арсенал -> Военный завод
            BuildTimeIntermediate = 24.0,
            BuildTimeComplete     = 60.0,
            MetalCost             = 450,
            EnergyCost            = 2600,
            MetalRepairCost       = 110,
            EnergyRepairCost      = 800,
            Upgrades              = {},
            BuildQueueModifier    = { ["mp_ammo"] = 1 },
        }))
end

-- ============================================================
--  ОТКЛЮЧЕНИЕ ВАНИЛЬНЫХ ЗАВОДОВ
-- ============================================================
for _, tname in ipairs({ "factory", "munitions" }) do
    local td = FindDevice(tname)
    if td then
        td.Enabled = false
    end
end

-- ============================================================
--  ВАНИЛЬНЫЕ ШАХТЫ: НОВЫЕ ТЕКСТУРЫ И ИКОНКИ
-- ============================================================
local mineIdx = IndexOfDevice("mine")
local mineBase = FindDevice("mine")
if mineIdx and mineBase and InheritType then
    Devices[mineIdx] = InheritType(mineBase, nil,
    {
        FileName = path .. "/devices/mine_mp.lua",
        Icon     = "hud-mpmine-icon",
        Detail   = "hud-detail-mpmine",
    })
end

local mine2Idx = IndexOfDevice("mine2")
local mine2Base = FindDevice("mine2")
if mine2Idx and mine2Base and InheritType then
    Devices[mine2Idx] = InheritType(mine2Base, nil,
    {
        FileName = path .. "/devices/mine2_mp.lua",
        Icon     = "hud-mpmine2-icon",
        Detail   = "hud-detail-mpmine2",
    })
end

-- ============================================================
--  НАШИ ВЕТРЯКИ (два уровня)
--  Ветряк 1 уровня: доступен для постройки из HUD
--  Ветряк 2 уровня (супер-турбина): строитСЯ ТОЛЬКО апгрейдом
--  (Enabled = false в HUD меню!)
-- ============================================================
local MP_WINDMILLS = true
MP_WindSrc = MP_WindSrc or {}

if MP_WINDMILLS and type(Devices) == "table" then
    for _, d in ipairs(Devices) do
        if d and type(d.FileName) == "string" and type(d.SaveName) == "string" then
            local f = d.FileName:lower()
            local s = d.SaveName:lower()
            local isWind = f:find("windmill") or (f:find("turbine") and not f:find("water"))
            if isWind then
                MP_WindSrc[d.SaveName] = d.FileName
                local lvl2 = f:find("2%.lua$") ~= nil or s:find("2") ~= nil or s:find("super") ~= nil or s:find("swind") ~= nil
                d.FileName = path .. (lvl2 and "/devices/windmill2_mp.lua"
                                            or "/devices/windmill_mp.lua")
                d.Icon     = lvl2 and "hud-mpwindmill2-icon" or "hud-mpwindmill-icon"
                d.Detail   = lvl2 and "hud-detail-mpwindmill2" or "hud-detail-mpwindmill"
                if lvl2 then
                    d.Enabled = false   -- ЗАПРЕЩЕНО строить сразу из худа: только апгрейд с 1 уровня!
                else
                    d.Enabled = true
                end
            end
        end
    end
end

-- ============================================================
--  MP: РЕСКИН ВАНИЛЬНОЙ БАТАРЕЙКИ В СТИЛЕ М1 (1x1)
-- ============================================================
table.insert(Sprites, DetailSprite("hud-detail-mpbattery", "HUD-Details-Battery", path))
table.insert(Sprites, ButtonSprite("hud-mpbattery-icon", "HUD/HUD-Battery", nil, ButtonSpriteBottom, nil, nil, path))

local function MP_FindBySubstr(substrs)
    if type(Devices) ~= "table" then return nil end
    for _, d in ipairs(Devices) do
        if d and type(d.SaveName) == "string" then
            local f = d.SaveName:lower()
            local ok = true
            for _, s in ipairs(substrs) do
                if not f:find(s, 1, true) then ok = false break end
            end
            if ok then return d end
        end
    end
    return nil
end

do
    local batt = (type(FindDevice) == "function" and FindDevice("battery")) or MP_FindBySubstr({ "batter" })
    if batt and batt.SaveName ~= nil then
        batt.FileName = path .. "/devices/battery_mp.lua"
        batt.Icon     = "hud-mpbattery-icon"
        batt.Detail   = "hud-detail-mpbattery"
        batt.Enabled  = true
    end
end

-- ============================================================
--  MP: РЕСКИН ВАНИЛЬНОГО СКЛАДА МЕТАЛЛА В СТИЛЕ М1
-- ============================================================
table.insert(Sprites, DetailSprite("hud-detail-mpstore", "HUD-Details-Metalstore", path))
table.insert(Sprites, ButtonSprite("hud-mpstore-icon", "HUD/HUD-Metalstore", nil, ButtonSpriteBottom, nil, nil, path))

do
    local store = nil
    if type(FindDevice) == "function" then
        store = FindDevice("metalstore") or FindDevice("metal_store") or FindDevice("metalstorage") or FindDevice("store")
    end
    if store == nil then store = MP_FindBySubstr({ "metal", "stor" }) end
    if store == nil then store = MP_FindBySubstr({ "store" }) end
    if store and store.SaveName ~= nil then
        store.FileName = path .. "/devices/metalstore_mp.lua"
        store.Icon     = "hud-mpstore-icon"
        store.Detail   = "hud-detail-mpstore"
        store.Enabled  = true
    else
        local baseDev = (type(FindDevice) == "function" and FindDevice("battery")) or (type(Devices) == "table" and Devices[1])
        if baseDev and InheritType then
            table.insert(Devices,
                InheritType(baseDev, nil,
                {
                    SaveName              = "metalstore",
                    FileName              = path .. "/devices/metalstore_mp.lua",
                    Icon                  = "hud-mpstore-icon",
                    Detail                = "hud-detail-mpstore",
                    Enabled               = true,
                    BuildTimeIntermediate = 8.0,
                    BuildTimeComplete     = 16.0,
                    MetalCost             = 200,
                    EnergyCost            = 500,
                    MetalRepairCost       = 40,
                    EnergyRepairCost      = 100,
                }))
        end
    end
end

-- ============================================================
--  MP: МЕШОК С ПЕСКОМ В СТИЛЕ МОДА (модель + иконка)
--  Перекрываем ванильный sandbags: новая текстура, новая иконка,
--  новая карточка деталей. Статы/стоимость оставляем ванильные.
-- ============================================================
table.insert(Sprites, DetailSprite("hud-detail-mpsandbags", "HUD-Details-MpSandbags", path))
table.insert(Sprites, ButtonSprite("hud-mpsandbags-icon", "HUD/HUD-MpSandbags", nil, ButtonSpriteBottom, nil, nil, path))

do
    local sb = (type(FindDevice) == "function" and FindDevice("sandbags"))
              or MP_FindBySubstr({ "sandbag" })
    if sb and sb.SaveName ~= nil then
        sb.FileName = path .. "/devices/sandbags_mp.lua"
        sb.Icon     = "hud-mpsandbags-icon"
        sb.Detail   = "hud-detail-mpsandbags"
        sb.Enabled  = true
    end
end

-- ============================================================
--  MP: REMOTE REPAIR STATION — "Ремонтная станция" (стиль мода)
--  Перенос и переработка мода repair_station: новая модель,
--  новые иконки. Механика (ремонт/тушение/очистка дыма) сохранена.
-- ============================================================
table.insert(Sprites, DetailSprite("hud-detail-mprepairstation", "HUD-Details-MpRepairStation", path))
table.insert(Sprites, ButtonSprite("hud-mprepairstation-icon", "HUD/HUD-MpRepairStation", nil, ButtonSpriteBottom, nil, nil, path))

-- Регистрируем устройство (если его ещё нет — например, мод repair_station выключен)
do
    local rs = (type(FindDevice) == "function" and FindDevice("repairstation"))
    local sandbagsIdx = (type(IndexOfDevice) == "function" and IndexOfDevice("sandbags")) or #Devices

    if rs and rs.SaveName ~= nil then
        -- устройство уже есть (мод repair_station активен) — только рескин
        rs.FileName = path .. "/devices/repairstation_mp.lua"
        rs.Icon     = "hud-mprepairstation-icon"
        rs.Detail   = "hud-detail-mprepairstation"
        rs.Enabled  = true
        rs.MetalCost       = 220
        rs.EnergyCost      = 1500
        rs.MetalRepairCost = 100
        rs.EnergyRepairCost = 750
        rs.BuildTimeComplete = 20
        rs.ScrapPeriod     = 5
    else
        -- своего устройства нет — создаём сами
        local baseDev = (type(FindDevice) == "function" and FindDevice("sandbags")) or Devices[1]
        if baseDev and type(InheritType) == "function" then
            table.insert(Devices, sandbagsIdx + 2,
                InheritType(baseDev, nil,
                {
                    SaveName              = "repairstation",
                    FileName              = path .. "/devices/repairstation_mp.lua",
                    Icon                  = "hud-mprepairstation-icon",
                    Detail                = "hud-detail-mprepairstation",
                    Enabled               = true,
                    Prerequisite          = "mpfactory",
                    BuildTimeIntermediate = 8.0,
                    BuildTimeComplete     = 20.0,
                    ScrapPeriod           = 5,
                    MetalCost             = 220,
                    EnergyCost            = 1500,
                    MetalRepairCost       = 100,
                    EnergyRepairCost      = 750,
                    MaxUpAngle            = StandardMaxUpAngle,
                    BuildOnGroundOnly     = false,
                    SelectEffect          = "ui/hud/devices/ui_devices",
                }))
        end
    end
end

-- ============================================================
--  СКРЫТИЕ БОЕПРИПАСОВ КОНТРОЛЯ И ПРИМАНКИ (High Seas / DLC2)
--  Убирает из ПКМ-меню боеприпасов DLC2-боеприпасы:
--    • Control Ammunition  (dlc2_ammo_control) — «боеприпасы контроля»
--    • Decoy Ammunition                        — «боеприпасы приманки»
--
--  Ванильные боеприпасы DLC2 лежат в зашитом dlc2.pack, их SaveName
--  в открытых файлах не видны. Поэтому гасим их ПАКЕТНО:
--    1) по прямому списку известных SaveName;
--    2) по подстроке в SaveName (decoy / control / приманк / контрол);
--    3) снимая ссылки из dlc2_Ammunition у всех оружий.
--
--  Основной механизм — d.Enabled = false (реально работает).
--  ExcludeUnlockAll оставлен на случай старого пути разблокировки.
-- ============================================================
do
    local HIDE_EXACT =
    {
        "ammo_decoy", "ammo_control",
        "dlc2_ammo_decoy", "dlc2_ammo_control",
        "decoyammo", "controlammo",
    }
    local HIDE_SUBSTR = { "decoy", "приманк", "diversion", "контрол" }
    local hidden = {}

    local function MP_IsHidden(name)
        if type(name) ~= "string" then return false end
        local low = name:lower()
        for _, exact in ipairs(HIDE_EXACT) do
            if low == exact:lower() then return true end
        end
        for _, sub in ipairs(HIDE_SUBSTR) do
            if low:find(sub, 1, true) then return true end
        end
        return false
    end

    -- 1+2. Гасим сами устройства-боеприпасы
    if type(Devices) == "table" then
        for _, d in ipairs(Devices) do
            if type(d) == "table" and MP_IsHidden(d.SaveName) then
                d.Enabled = false
                d.ExcludeUnlockAll = true
                d.Prerequisite = nil
                hidden[#hidden + 1] = d.SaveName
            end
        end
    end

    if type(Log) == "function" and #hidden > 0 then
        pcall(Log, "[MILITARYPACK] hidden ammo: " .. table.concat(hidden, ", "))
    end

    -- 3. Снимаем ссылки приманки/контроля из ПКМ-меню боеприпасов
    if type(dlc2_Ammunition) == "table" then
        for i = #dlc2_Ammunition, 1, -1 do
            local entry = dlc2_Ammunition[i]
            local drop = false
            if type(entry) == "table" and type(entry.Devices) == "table" then
                for _, ref in ipairs(entry.Devices) do
                    if type(ref) == "table" and MP_IsHidden(ref.Name) then drop = true break end
                end
            end
            if drop then table.remove(dlc2_Ammunition, i) end
        end
    end
end
