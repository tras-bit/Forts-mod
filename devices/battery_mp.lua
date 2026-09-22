-- ============================================================
--  Military Pack: БАТАРЕЯ (1 клетка, M1 style)
--  Компактный армейский накопитель энергии в 1 стандартную клетку.
--  Хранит 2000 ед. энергии, взрывается при разрушении.
-- ============================================================

ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/device_explode.lua"
DestroyUnderwaterEffect = "mods/dlc2/effects/device_explode_submerged.lua"

Scale = 1.0
SelectionWidth = 46.0
SelectionHeight = 44.0
SelectionOffset = { 0.0, -44.0 }

Mass = 40.0
HitPoints = 100.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 2000.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DrawBracket = false
DrawBehindTerrain = true
NoReclaim = false
TeamOwned = true
IgnitePlatformOnDestruct = true

-- Взрывоопасность батареи
DeviceSplashDamage = 150
DeviceSplashDamageMaxRadius = 180
DeviceSplashDamageDelay = 0.1
IncendiaryRadius = 60
IncendiaryRadiusHeated = 80
StructureSplashDamage = 120
StructureSplashDamageMaxRadius = 150

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "mp-battery-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/devices/media/battery_mp.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
}

Root =
{
    Name = "Battery",
    Angle = 0,
    Pivot = { 0, -0.58 },
    PivotOffset = { 0, 0 },
    Sprite = "mp-battery-base",
}
