-- ============================================================
--  ЗРК (zrk) — зенитный ракетный комплекс, самостоятельный конфиг
--  Тяжёлая ПВО-точка: залп по выбору игрока от 2 до 10 ракет
--  (режимы в конце файла, система боеприпасов High Seas).
-- ============================================================

dofile("ui/uihelper.lua")

Scale = 1
SelectionWidth = 100.0
SelectionHeight = 60.0
SelectionOffset = { -20, -60 }
RecessionBox =
{
    Size = { 200, 25 },
    Offset = { -300, -70 },
}
CanFlip = false

WeaponMass = 200.0
HitPoints = 700.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DeviceSplashDamage = 150
DeviceSplashDamageMaxRadius = 400
DeviceSplashDamageDelay = 0.2
IncendiaryRadius = 120
IncendiaryRadiusHeated = 150
StructureSplashDamage = 200
StructureSplashDamageMaxRadius = 150

FireEffect = path .. "/effects/mpsam_salvo.lua"
ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/machinegun_explode.lua"
ShellEffect = "effects/shell_eject_small.lua"
ReloadEffect = "effects/minigun_reload.lua"
ReloadEffectOffset = -0.5

Projectile = "aamissile"
BarrelLength = 110.0
MinFireClearance = 700
FireClearanceOffsetInner = 20
FireClearanceOffsetOuter = 40
AttractZoomOutDuration = 5

ReloadTime = 40.0            -- тяжёлая перезарядка засылайки
ReloadTimeIncludesBurst = false
RoundsEachBurst = 2          -- залп из двух ракет
RoundPeriod = 0.25

MinFireSpeed = 9000.0
MaxFireSpeed = 9000.1
MinFireRadius = 300.0
MaxFireRadius = 1600.0
MinFireAngle = 5
MaxFireAngle = 85            -- почти только небо

-- ============================================================
--  ВОЗДУШНЫЙ РАЗРЫВ РАКЕТЫ (airburst)
-- ============================================================
--  Эти три поля — РЕАЛЬНЫЙ механизм движка (проверено по
--  Forts.exe и по ванильному моду weapon_pack):
--     TriggerProjectileAgeAction — оружие запускает действие
--                                  Effects.Age у снаряда;
--     MinAgeTrigger / MaxAgeTrigger — окно срабатывания в СЕКУНДАХ.
--  Без них Age-действие снаряда не проигрывается вообще.
--  Эталон — оружие flak в weapon_pack: 0.3 / 1.1.
TriggerProjectileAgeAction = true
MinAgeTrigger = 0.3
MaxAgeTrigger = 1.1
KickbackMean = 25
KickbackStdDev = 6
MouseSensitivityFactor = 0.5
PanDuration = 0
FireStdDev = 0.012
FireStdDevAuto = 0.015

Recoil = 150000
EnergyFireCost = 800.0
MetalFireCost = 60.0

ShowFireAngle = true

BarrelRecoilLimit = -0.2
BarrelRecoilSpeed = -2
BarrelReturnForce = 0.5

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "zrk-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/zrk/base.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "zrk-head",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/zrk/head.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
}

Root =
{
    Name = "ZRK",
    Angle = 0,
    Pivot = { 0, -0.55 },
    PivotOffset = { 0, 0 },
    Sprite = "zrk-base",
    UserData = 0,

    ChildrenBehind =
    {
        {
            Name = "Head",
            Angle = 45,
            Pivot = { 0, -0.1 },
            PivotOffset = { 0.05, 0 },
            Sprite = "zrk-head",
            UserData = 50,

            ChildrenInFront =
            {
                { Name = "Hardpoint0", Angle = 90, Pivot = { 0.15, 0 }, PivotOffset = { 0, 0 } },
                { Name = "LaserSight", Angle = 90, Pivot = { 0, -0.25 }, PivotOffset = { 0, 0 } },
                { Name = "Chamber", Angle = 0, Pivot = { -0.35, 0.1 }, PivotOffset = { 0, 0 } },
            },
        },
        { Name = "Icon", Pivot = { 0, 0.5 } },
    },
}

table.insert(Sprites, ButtonSprite("hud-context-ammo-zrk2", "context/HUD-Ammo-ZRK2", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-zrk4", "context/HUD-Ammo-ZRK4", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-zrk6", "context/HUD-Ammo-ZRK6", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-zrk8", "context/HUD-Ammo-ZRK8", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-zrk10", "context/HUD-Ammo-ZRK10", nil, nil, nil, nil, path))

-- ============================================================
--  ВЫБОР РАДИУСА РАЗРЫВА (как у зенитки)
-- ============================================================
--  Каждая строка селектора — свой снаряд со своей зоной
--  поражения. Радиус и число осколков заданы в
--  weapons/projectile_list.lua (aamissile_r1..r4):
--     r1 — узкий   (0.7x радиуса, 16 осколков)
--     r2 — средний (1.0x,           24)
--     r3 — широкий (1.4x,           36)
--     r4 — огромный (1.9x,          48)
--  RoundsEachBurst = 2 означает двойной пуск на каждый выбор.
dlc2_Ammunition =
{
    {
        StringId   = "Weapon.MPZRK2",
        Sprite     = "hud-context-ammo-zrk2",
        Projectile = "aamissile_r1",
        Devices    = { { Name = "ammo_sam", Consume = true } },
    },
    {
        StringId        = "Weapon.MPZRK4",
        Sprite          = "hud-context-ammo-zrk4",
        Projectile      = "aamissile_r2",
        RoundsEachBurst = 2,
        RoundPeriod     = 0.22,
        ReloadTime      = 55.0,
        EnergyFireCost  = 1500.0,
        MetalFireCost   = 120.0,
        Devices         = { { Name = "ammo_sam", Consume = true } },
    },
    {
        StringId        = "Weapon.MPZRK6",
        Sprite          = "hud-context-ammo-zrk6",
        Projectile      = "aamissile_r3",
        RoundsEachBurst = 2,
        RoundPeriod     = 0.20,
        ReloadTime      = 70.0,
        EnergyFireCost  = 2200.0,
        MetalFireCost   = 180.0,
        Devices         = { { Name = "ammo_sam", Consume = true } },
    },
    {
        StringId        = "Weapon.MPZRK8",
        Sprite          = "hud-context-ammo-zrk8",
        Projectile      = "aamissile_r4",
        RoundsEachBurst = 2,
        RoundPeriod     = 0.18,
        ReloadTime      = 85.0,
        EnergyFireCost  = 3000.0,
        MetalFireCost   = 240.0,
        Devices         = { { Name = "ammo_sam", Consume = true } },
    },
    {
        StringId        = "Weapon.MPZRK10",
        Sprite          = "hud-context-ammo-zrk10",
        Projectile      = "aamissile_r4",
        RoundsEachBurst = 3,
        RoundPeriod     = 0.16,
        ReloadTime      = 100.0,
        EnergyFireCost  = 3800.0,
        MetalFireCost   = 300.0,
        Devices         = { { Name = "ammo_sam", Consume = true } },
    },
}

