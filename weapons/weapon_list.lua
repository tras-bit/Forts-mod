table.insert(Sprites, DetailSprite("hud-detail-typhoon", "HUD-Details-TYPHOON", path))
table.insert(Sprites, ButtonSprite("hud-typhoon-icon", "HUD/HUD-TYPHOON", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-group-typhoon", "HUD/HUD-TYPHOON", nil, ButtonSpriteBottom, nil, nil, path))
-- ============================================================
--  Military Pack: регистрация оружия
-- ============================================================

-- ---------- Значки и картинки для HUD ----------
table.insert(Sprites, DetailSprite("hud-detail-clustercannon", "HUD-Details-ClusterCannon", path))
table.insert(Sprites, ButtonSprite("hud-clustercannon-icon", "HUD/HUD-ClusterCannon", nil, ButtonSpriteBottom, nil, nil, path))

table.insert(Sprites, DetailSprite("hud-detail-clustercannon2", "HUD-Details-CLUSTER2", path))
table.insert(Sprites, ButtonSprite("hud-clustercannon2-icon", "HUD/HUD-CLUSTER2", nil, ButtonSpriteBottom, nil, nil, path))

table.insert(Sprites, DetailSprite("hud-detail-manpads", "HUD-Details-MANPADS", path))
table.insert(Sprites, ButtonSprite("hud-manpads-icon", "HUD/HUD-MANPADS", nil, ButtonSpriteBottom, nil, nil, path))

table.insert(Sprites, DetailSprite("hud-detail-zrk", "HUD-Details-ZRK", path))
table.insert(Sprites, ButtonSprite("hud-zrk-icon", "HUD/HUD-ZRK", nil, ButtonSpriteBottom, nil, nil, path))

table.insert(Sprites, DetailSprite("hud-detail-shrapnel20", "HUD-Details-SHRAPNEL20", path))
table.insert(Sprites, ButtonSprite("hud-shrapnel20-icon", "HUD/HUD-SHRAPNEL20", nil, ButtonSpriteBottom, nil, nil, path))

table.insert(Sprites, DetailSprite("hud-detail-intercept", "HUD-Details-INTERCEPT", path))
table.insert(Sprites, ButtonSprite("hud-intercept-icon", "HUD/HUD-INTERCEPT", nil, ButtonSpriteBottom, nil, nil, path))

table.insert(Sprites, DetailSprite("hud-detail-flakgun", "HUD-Details-FLAKGUN", path))
table.insert(Sprites, ButtonSprite("hud-flakgun-icon", "HUD/HUD-FLAKGUN", nil, ButtonSpriteBottom, nil, nil, path))

-- Групповые кнопки для меню оружия
table.insert(Sprites, ButtonSprite("hud-group-clustercannon", "HUD/HUD-ClusterCannon", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-group-clustercannon2", "HUD/HUD-CLUSTER2", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-group-manpads", "HUD/HUD-MANPADS", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-group-zrk", "HUD/HUD-ZRK", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-group-shrapnel20", "HUD/HUD-SHRAPNEL20", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-group-intercept", "HUD/HUD-INTERCEPT", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-group-flakgun", "HUD/HUD-FLAKGUN", nil, ButtonSpriteBottom, nil, nil, path))

if Weapons == nil then
    Weapons = {}
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

local function CloneWeapon(saveName)
    if type(Weapons) ~= "table" then return nil end
    for _, w in ipairs(Weapons) do
        if w and w.SaveName == saveName then return DeepCopy(w) end
    end
    return nil
end

local function SetupOurs(w, prereq)
    w.CompatibleGroupTypes = {}
    w.Upgrades = {}
    w.GroupButton = "hud-group-" .. w.SaveName
    w.Prerequisite = prereq or "mpfactory"
    w.Enabled = true
end

-- 1. Кассетная пушка М1
local cc = CloneWeapon("cannon")
if cc then
    cc.SaveName          = "clustercannon"
    cc.FileName          = path .. "/weapons/clustercannon.lua"
    cc.Icon              = "hud-clustercannon-icon"
    cc.Detail            = "hud-detail-clustercannon"
    cc.MetalCost         = 350
    cc.EnergyCost        = 3500
    cc.MetalRepairCost   = 150
    cc.EnergyRepairCost  = 1200
    cc.BuildTimeComplete = 50
    SetupOurs(cc, "mpfactory")
    table.insert(Weapons, cc)
end

-- 2. Кассетная пушка М2
local cc2 = CloneWeapon("cannon")
if cc2 then
    cc2.SaveName          = "clustercannon2"
    cc2.FileName          = path .. "/weapons/clustercannon2.lua"
    cc2.Icon              = "hud-clustercannon2-icon"
    cc2.Detail            = "hud-detail-clustercannon2"
    cc2.MetalCost         = 600
    cc2.EnergyCost        = 5000
    cc2.MetalRepairCost   = 250
    cc2.EnergyRepairCost  = 2000
    cc2.BuildTimeComplete = 65
    SetupOurs(cc2, "mpfactory")
    table.insert(Weapons, cc2)
end

-- 3. ПЗРК
local mp = CloneWeapon("cannon")
if mp then
    mp.SaveName          = "manpads"
    mp.FileName          = path .. "/weapons/manpads.lua"
    mp.Icon              = "hud-manpads-icon"
    mp.Detail            = "hud-detail-manpads"
    mp.MetalCost         = 150
    mp.EnergyCost        = 1500
    mp.MetalRepairCost   = 75
    mp.EnergyRepairCost  = 750
    mp.BuildTimeComplete = 30
    SetupOurs(mp, "mpfactory")
    table.insert(Weapons, mp)
end

-- 4. ЗРК
local sam = CloneWeapon("cannon")
if sam then
    sam.SaveName          = "zrk"
    sam.FileName          = path .. "/weapons/zrk.lua"
    sam.Icon              = "hud-zrk-icon"
    sam.Detail            = "hud-detail-zrk"
    sam.MetalCost         = 700
    sam.EnergyCost        = 5000
    sam.MetalRepairCost   = 200
    sam.EnergyRepairCost  = 1500
    sam.BuildTimeComplete = 60
    SetupOurs(sam, "mpfactory")
    table.insert(Weapons, sam)
end

-- 5. ЗРК-Перехватчик
local ic = CloneWeapon("cannon")
if ic then
    ic.SaveName          = "intercept"
    ic.FileName          = path .. "/weapons/intercept.lua"
    ic.Icon              = "hud-intercept-icon"
    ic.Detail            = "hud-detail-intercept"
    ic.MetalCost         = 350
    ic.EnergyCost        = 2800
    ic.MetalRepairCost   = 150
    ic.EnergyRepairCost  = 1000
    ic.BuildTimeComplete = 40
    SetupOurs(ic, "mpfactory")
    table.insert(Weapons, ic)
end

-- 6. Автопушка «Шрапнель-20»
local sp = CloneWeapon("cannon")
if sp then
    sp.SaveName          = "shrapnel20"
    sp.FileName          = path .. "/weapons/shrapnel20.lua"
    sp.Icon              = "hud-shrapnel20-icon"
    sp.Detail            = "hud-detail-shrapnel20"
    sp.MetalCost         = 380
    sp.EnergyCost        = 3200
    sp.MetalRepairCost   = 150
    sp.EnergyRepairCost  = 1100
    sp.BuildTimeComplete = 45
    SetupOurs(sp, "mpfactory")
    table.insert(Weapons, sp)
end

-- 7. Тяжёлая зенитка ЗСУ (flakgun)
local fg = CloneWeapon("cannon")
if fg then
    fg.SaveName          = "flakgun"
    fg.FileName          = path .. "/weapons/flakgun.lua"
    fg.Icon              = "hud-flakgun-icon"
    fg.Detail            = "hud-detail-flakgun"
    fg.MetalCost         = 400
    fg.EnergyCost        = 3000
    fg.MetalRepairCost   = 150
    fg.EnergyRepairCost  = 1000
    fg.BuildTimeComplete = 45
    SetupOurs(fg, "mpfactory")
    table.insert(Weapons, fg)
end

-- Отключение всего ванильного оружия

-- ============================================================
--  8. ТЯЖЁЛАЯ УСТАНОВКА «ТАЙФУН» (typhoon, 1x2)
-- ============================================================
local tph = CloneWeapon("cannon")
if tph then
    tph.SaveName          = "typhoon"
    tph.FileName          = path .. "/weapons/typhoon.lua"
    tph.Icon              = "hud-typhoon-icon"
    tph.Detail            = "hud-detail-typhoon"
    tph.MetalCost         = 850
    tph.EnergyCost        = 6000
    tph.MetalRepairCost   = 300
    tph.EnergyRepairCost  = 2200
    tph.BuildTimeComplete = 70
    SetupOurs(tph, "mpfactory")
    table.insert(Weapons, tph)
end

local OUR_WEAPONS =
{
    clustercannon  = true,
    clustercannon2 = true,
    manpads        = true,
    zrk            = true,
    intercept      = true,
    shrapnel20     = true,
    flakgun        = true,
    typhoon        = true,
}

-- ============================================================
--  КАПИТАН ФАНТОМ: ПЕРЕМЕЩЕНИЕ ОРУЖИЯ ОТКЛЮЧЕНО
--  Переменная MovePeriod (в weapon_list.lua) задаёт длительность
--  перемещения пассивкой Фантома. Ставим недостижимое значение:
--  пушку начать двигать можно, а довезти — никогда.
-- ============================================================
local MP_NO_MOVE_PERIOD = 999999

if type(Weapons) == "table" then
    for _, w in ipairs(Weapons) do
        if w and w.SaveName then
            if OUR_WEAPONS[w.SaveName] then
                w.Enabled = true
            else
                w.Enabled = false
            end
            w.MovePeriod = MP_NO_MOVE_PERIOD
        end
    end
end

-- Перестраховка: если командирский мод Фантома правит список позже,
-- на ApplyMod (наш Priority = 10, применяемся последними) всё вернём.
if type(RegisterApplyMod) == "function" then
    RegisterApplyMod(function()
        if type(Weapons) ~= "table" then return end
        for _, w in ipairs(Weapons) do
            if w then w.MovePeriod = MP_NO_MOVE_PERIOD end
        end
    end)
end
