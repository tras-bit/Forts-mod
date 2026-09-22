-- ============================================================
--  ЯЩИК БОЕПРИПАСОВ (объединённый конфиг для всех типов, v4.2)
--  Физическая коробка на форте: маленькая, взрывоопасная.
--  При разрушении бьёт мощным сплэшем и выбрасывает сотни
--  осколков через OnDeviceDestroyed в script.lua.
--
--  ВАЖНО: этот файл подключается движком ОТДЕЛЬНО для каждого
--  боеприпаса из ammo_list.lua (12 записей). Спрайт регистрируется
--  на каждом подключении, поэтому без защиты движок пишет в лог:
--      Warning: duplicate sprite name mp-ammo-crates
--  Проверяем, не добавлен ли спрайт ранее, и добавляем один раз.
-- ============================================================

ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/device_explode.lua"
DestroyUnderwaterEffect = "mods/dlc2/effects/device_explode_submerged.lua"
ConsumeEffect = "mods/dlc2/effects/ammo_consumption.lua"
Scale = 1
dlc2_BuildAnywhere = true
SelectionWidth = 36
SelectionHeight = 24
SelectionOffset = { 0.0, -24.5 }
Mass = 20.0
HitPoints = 160.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DrawBracket = false
DrawBehindTerrain = true
NoReclaim = false
TeamOwned = true
IgnitePlatformOnDestruct = true

-- боеприпас взрывоопасен: разрушенный ящик бьёт мощным сплэшем
DeviceSplashDamage = 250
DeviceSplashDamageMaxRadius = 250
DeviceSplashDamageDelay = 0.05
IncendiaryRadius = 120
IncendiaryRadiusHeated = 160
StructureSplashDamage = 200
StructureSplashDamageMaxRadius = 220

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

-- Регистрируем спрайт только один раз — файл подключается на каждый
-- из 12 типов боеприпасов, иначе движок ругается на дубликат.
local function AlreadyHasSprite(name)
    if type(Sprites) ~= "table" then return false end
    for _, sp in ipairs(Sprites) do
        if type(sp) == "table" and sp.Name == name then return true end
    end
    return false
end

if not AlreadyHasSprite("mp-ammo-crates") then
    Sprites =
    {
        {
            Name = "mp-ammo-crates",
            States =
            {
                Normal = { Frames = { { texture = path .. "/devices/media/ammocrates.png" }, mipmap = true, }, },
                Idle = Normal,
            },
        },
    }
end

Root =
{
    Name = "AmmoCrates",
    Angle = 0,
    Pivot = { 0, -0.58 },
    PivotOffset = { 0, 0 },
    Sprite = "mp-ammo-crates",
}
