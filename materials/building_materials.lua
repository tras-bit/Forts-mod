-- ============================================================
--  Military Pack: строительные материалы (v4.7)
--  Сбалансированная прочность дверей и брони (ХП уменьшено в 2 раза)
--  Новые иконки ПКМ-меню в стиле мода для ВСЕХ материалов.
-- ============================================================

-- ============================================================
--  НОВЫЕ ИКОНКИ МАТЕРИАЛОВ (ПКМ по балке)
--  Перекрывают ванильные контекстные кнопки через ReplaceSprite.
--  Спрайты уже зарегистрированы ванильным building_materials.lua,
--  поэтому просто подменяем текстуры у существующих имён.
-- ============================================================
do
    local MP_MAT_ICONS =
    {
        { "context-bracing",     "HUD-Buttons-Bracing"     },
        { "context-backbracing", "HUD-Buttons-BackBracing" },
        { "context-door",        "HUD-Buttons-Door"        },
        { "context-armor",       "HUD-Buttons-Armour"      },
        { "context-armoureddoor","HUD-Buttons-ArmouredDoor"},
        { "context-heavyarmour", "HUD-Buttons-HeavyArmour" },
        { "context-lightarmour", "HUD-Buttons-LightArmour" },
    }
    if type(Sprites) == "table" then
        for _, pair in ipairs(MP_MAT_ICONS) do
            local spriteName, texName = pair[1], pair[2]
            local states =
            {
                Normal   = { Frames = { { texture = path .. "/ui/textures/context/" .. texName .. "-A.tga" }, }, },
                Rollover = { Frames = { { texture = path .. "/ui/textures/context/" .. texName .. "-R.tga" }, }, },
                Pressed  = { Frames = { { texture = path .. "/ui/textures/context/" .. texName .. "-S.tga" }, }, },
                Disabled = { Frames = { { texture = path .. "/ui/textures/context/" .. texName .. "-D.tga" }, }, },
            }
            local replaced = false
            for _, sp in ipairs(Sprites) do
                if type(sp) == "table" and sp.Name == spriteName then
                    sp.States = states
                    replaced = true
                    break
                end
            end
            -- если спрайта ещё нет (напр. context-strut) — регистрируем сами
            if not replaced then
                table.insert(Sprites, { Name = spriteName, States = states })
            end
        end
    end
end

-- ============================================================
--  НОВЫЕ ИКОНКИ МАТЕРИАЛОВ В ПАЛИТРЕ (левая панель стройки)
--  Ванилла берёт иконки из ui/textures/HUD/Materials-*.dds
--  (128x256, превью балки). Подменяем их на текстуры мода.
-- ============================================================
do
    local MP_PALETTE =
    {
        -- имя спрайта   -> имя текстуры мода
        { "hud-bracing-icon",      "Materials-Bracing"      },
        { "hud-bg-bracing-icon",   "Materials-Bracing_BG"   },
        { "hud-camo-icon",         "Materials-Bracing"      },
        { "hud-armor-icon",        "Materials-Armour"       },
        { "hud-door-icon",         "Materials-Door"         },
        { "hud-armoureddoor-icon", "Materials-ArmouredDoor" },
        { "hud-heavyarmour-icon",  "Materials-HeavyArmour"  },
        { "hud-lightarmour-icon",  "Materials-LightArmour"  },
    }
    local MP_BOTTOM = 0.664   -- как в ванили: обрезка «земли» снизу

    local function MP_PaletteStates(texName)
        local base = path .. "/ui/textures/HUD/" .. texName
        return
        {
            Normal   = { Frames = { { texture = base .. "-A.dds", bottom = MP_BOTTOM }, }, },
            Rollover = { Frames = { { texture = base .. "-R.dds", bottom = MP_BOTTOM }, }, },
            Pressed  = { Frames = { { texture = base .. "-S.dds", bottom = MP_BOTTOM }, }, },
            Disabled = { Frames = { { texture = base .. "-D.dds", bottom = MP_BOTTOM }, }, },
        }
    end

    if type(Sprites) == "table" then
        for _, pair in ipairs(MP_PALETTE) do
            local spriteName, texName = pair[1], pair[2]
            local states = MP_PaletteStates(texName)
            local replaced = false
            for _, sp in ipairs(Sprites) do
                if type(sp) == "table" and sp.Name == spriteName then
                    sp.States = states
                    replaced = true
                    break
                end
            end
            if not replaced then
                table.insert(Sprites, { Name = spriteName, States = states })
            end
        end
    end
end

if Materials == nil then
    Materials = {}
end

local function DeepCopy(src, seen)
    if type(src) ~= "table" then return src end
    if seen and seen[src] then return seen[src] end
    local dst = {}
    seen = seen or {}
    seen[src] = dst
    for k, v in pairs(src) do
        dst[DeepCopy(k, seen)] = DeepCopy(v, seen)
    end
    return dst
end

local function FindMaterial(saveName)
    if type(Materials) ~= "table" then return nil end
    for _, m in ipairs(Materials) do
        if m and m.SaveName == saveName then return m end
    end
    return nil
end

local function ScaleField(t, key, f)
    if t and type(t[key]) == "number" then t[key] = t[key] * f end
end

local function ScaleNumericTable(t, f)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do
        if type(v) == "number" then t[k] = v * f end
    end
end

local function ScaleCost(t, f)
    ScaleField(t, "MetalBuildCost", f)
    ScaleField(t, "EnergyBuildCost", f)
    ScaleField(t, "MetalCost", f)
    ScaleField(t, "EnergyCost", f)
end

local function RegisterBeamSprite(spriteName, textureFile)
    table.insert(Sprites,
    {
        Name = spriteName,
        States =
        {
            Normal = { Frames = { { texture = path .. "/materials/media/" .. textureFile }, mipmap = true, }, },
            Idle = Normal,
        },
    })
    return spriteName
end

-- ============================================================
--  0. БАЗОВЫЕ ДВЕРИ (door) — ПРОЧНОСТЬ x2.0 (КАК ЛЁГКАЯ БРОНЯ)
--  Сбалансированная защита: держат осколки и пули, не будучи имбой
-- ============================================================
local baseDoor = FindMaterial("door")
if baseDoor then
    ScaleNumericTable(baseDoor.HitPoints, 2.0)
    if type(baseDoor.HitPoints) == "number" then
        baseDoor.HitPoints = baseDoor.HitPoints * 2.0
    end
    if type(baseDoor.HitPoints) == "table" then
        local shrapnelList = { "machinegun", "cannon20mm", "cluster20mm", "clusterpellet", "mp_bullet", "mp_flak", "flak", "shrapnelshell" }
        for _, k in ipairs(shrapnelList) do
            if baseDoor.HitPoints[k] then
                baseDoor.HitPoints[k] = baseDoor.HitPoints[k] * 1.2
            else
                local baseVal = baseDoor.HitPoints["machinegun"] or baseDoor.HitPoints["default"] or 400
                baseDoor.HitPoints[k] = baseVal * 1.2
            end
        end
    end
end

-- ============================================================
--  1. ТЯЖЁЛАЯ БРОНЕДВЕРЬ (armoureddoor) — ПРОЧНОСТЬ x4.0
--  Отличная защита амбразур пушек против прямого огня
-- ============================================================
local doorRef = FindMaterial("door")
if doorRef then
    local m = DeepCopy(doorRef)
    m.SaveName = "armoureddoor"
    m.Context  = "context-armoureddoor"
    m.Sprite   = RegisterBeamSprite("mp-armoureddoor", "armoureddoor.png")

    ScaleNumericTable(m.HitPoints, 2.0) -- x2 от двери = x4 от ваниллы
    if type(m.HitPoints) == "number" then
        m.HitPoints = m.HitPoints * 2.0
    end
    ScaleCost(m, 1.8)
    ScaleField(m, "BuildTime", 1.3)
    ScaleField(m, "ScrapTime", 1.3)

    table.insert(Materials, m)
    if type(DefaultConversions) == "table" then
        table.insert(DefaultConversions, "armoureddoor")
    end
end

-- ============================================================
--  2. УСИЛЕННАЯ БРОНЯ (heavyarmour) — прочность x2.5
-- ============================================================
local armour = FindMaterial("armour")
if armour then
    local m = DeepCopy(armour)
    m.SaveName = "heavyarmour"
    m.Context  = "context-heavyarmour"
    m.Sprite   = RegisterBeamSprite("mp-heavyarmour", "heavyarmour.png")

    ScaleNumericTable(m.HitPoints, 2.5)
    if type(m.HitPoints) == "number" then m.HitPoints = m.HitPoints * 2.5 end
    ScaleField(m, "Stiffness", 1.3)
    ScaleField(m, "Mass", 1.3)
    ScaleCost(m, 2.2)
    ScaleField(m, "BuildTime", 1.5)
    ScaleField(m, "ScrapTime", 1.5)
    if type(m.WeightPer100) == "number" then
        m.WeightPer100 = m.WeightPer100 * 1.3
    end

    table.insert(Materials, m)
    if type(DefaultConversions) == "table" then
        table.insert(DefaultConversions, "heavyarmour")
    end
end

-- ============================================================
--  3. ЛЁГКАЯ БРОНЯ (lightarmour) — дешёвая противоосколочная
--     Держит осколки и пули (x1.8), уязвима к прямым попаданиям (x0.9)
-- ============================================================
local armour2 = FindMaterial("armour")
if armour2 then
    local m = DeepCopy(armour2)
    m.SaveName = "lightarmour"
    m.Context  = "context-lightarmour"
    m.Sprite   = RegisterBeamSprite("mp-lightarmour", "lightarmour.png")

    ScaleCost(m, 1.1)
    ScaleField(m, "BuildTime", 0.8)
    ScaleField(m, "ScrapTime", 0.8)

    local SHRAP =
    {
        machinegun = true, cannon20mm = true, cluster20mm = true,
        clusterpellet = true, mp_bullet = true, mp_flak = true,
        flak = true, shrapnelshell = true,
    }
    if type(m.HitPoints) == "table" then
        for k, v in pairs(m.HitPoints) do
            m.HitPoints[k] = SHRAP[k] and v * 1.8 or v * 0.9
        end
        local base = m.HitPoints["machinegun"] or m.HitPoints["cannon20mm"] or 300
        for _, k in ipairs({ "cluster20mm", "clusterpellet", "mp_bullet", "mp_flak", "shrapnelshell" }) do
            m.HitPoints[k] = base * 1.8
        end
    elseif type(m.HitPoints) == "number" then
        m.HitPoints = m.HitPoints * 1.3
    end

    table.insert(Materials, m)
    if type(DefaultConversions) == "table" then
        table.insert(DefaultConversions, "lightarmour")
    end
end

-- ============================================================
--  ОСТАВЛЯЕМ ТОЛЬКО: дерево, металл, двери, броня,
--  бронедвери, усиленная броня, лёгкая броня.
-- ============================================================
local ALLOWED_MATERIALS =
{
    bracing       = true,  -- обычное дерево
    backbracing   = true,  -- фоновое дерево
    strut         = true,  -- металл
    door          = true,  -- двери (усилены в 2 раза)
    armour        = true,  -- броня
    armoureddoor  = true,  -- модовая бронедверь (усилена в 4 раза)
    heavyarmour   = true,  -- модовая усиленная броня
    lightarmour   = true,  -- модовая лёгкая броня
}

if type(Materials) == "table" then
    for _, m in ipairs(Materials) do
        if m and m.SaveName then
            if ALLOWED_MATERIALS[m.SaveName] then
                m.Enabled = true
            else
                m.Enabled = false
            end
            -- свои иконки палитры для материалов мода
            if m.SaveName == "armoureddoor" then
                m.Icon = "hud-armoureddoor-icon"
            elseif m.SaveName == "heavyarmour" then
                m.Icon = "hud-heavyarmour-icon"
            elseif m.SaveName == "lightarmour" then
                m.Icon = "hud-lightarmour-icon"
            end
        end
    end
end

-- Фильтруем меню конверсий ПКМ
if type(DefaultConversions) == "table" then
    local kept = {}
    for _, name in ipairs(DefaultConversions) do
        if ALLOWED_MATERIALS[name] then
            table.insert(kept, name)
        end
    end
    for i = #DefaultConversions, 1, -1 do
        DefaultConversions[i] = nil
    end
    for _, name in ipairs(kept) do
        table.insert(DefaultConversions, name)
    end
end
