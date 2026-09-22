-- ============================================================
--  ВОЕННЫЙ ЗАВОД — конфиг устройства (v1.5)
--  База — структура ванильного devices/tier3factory.lua.
--  v1.5: ванильные анимации (мигающая вывеска + будка рабочего)
--  УБРАНЫ — они ложились поверх нашей модели. Остался только
--  наш спрайт. Модель увеличена на ~20% (108x61.5 ед.),
--  коллизия подогнана (с запасом сверху, как у ваниллы).
-- ============================================================

ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyUnderwaterEffect = "mods/dlc2/effects/device_explode_submerged.lua"
Scale = 1
SelectionWidth = 92
SelectionHeight = 52.5
SelectionOffset = { 0.0, -53 }
Mass = 120.0
HitPoints = 600.0          -- ванилла 400, наш корпус бронированный
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

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

-- Только наша текстура: devices/media/factory.png (432x246 px)
Sprites =
{
    {
        Name = "mp-factory-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/devices/media/factory.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
}

Root =
{
    Name = "Factory",
    Angle = 0,
    Pivot = { 0, -0.58 },
    PivotOffset = { 0, 0 },
    Sprite = "mp-factory-base",
}
