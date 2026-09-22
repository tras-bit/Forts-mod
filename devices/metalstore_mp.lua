-- ============================================================
--  Military Pack: СКЛАД МЕТАЛЛА (1 клетка, M1 style)
--  Компактный армейский склад металла в 1 стандартную клетку.
--  Хранит 300 ед. металла. Ставится на платформы (не шахта!).
-- ============================================================

ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/device_explode.lua"
DestroyUnderwaterEffect = "mods/dlc2/effects/device_explode_submerged.lua"

Scale = 1.0
SelectionWidth = 46.0
SelectionHeight = 44.0
SelectionOffset = { 0.0, -44.0 }

Mass = 60.0
HitPoints = 100.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 300.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DrawBracket = false
DrawBehindTerrain = true
NoReclaim = false
TeamOwned = true
IgnitePlatformOnDestruct = false

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "mp-metalstore-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/devices/media/metalstore_mp.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
}

Root =
{
    Name = "MetalStore",
    Angle = 0,
    Pivot = { 0, -0.58 },
    PivotOffset = { 0, 0 },
    Sprite = "mp-metalstore-base",
}
