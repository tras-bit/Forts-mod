-- ============================================================
--  Military Pack: ПЗРК (manpads.lua)
--  Переносной зенитно-ракетный комплекс
-- ============================================================

dofile("ui/uihelper.lua")

Scale = 1
SelectionWidth = 80.0
SelectionHeight = 40.0
SelectionOffset = { -20.0, -40.0 }
RecessionBox =
{
    Size = { 200, 25 },
    Offset = { -300, -70 },
}
CanFlip = false

WeaponMass = 120.0
HitPoints = 450.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DeviceSplashDamage = 100
DeviceSplashDamageMaxRadius = 300
DeviceSplashDamageDelay = 0.2
IncendiaryRadius = 80
IncendiaryRadiusHeated = 120
StructureSplashDamage = 120
StructureSplashDamageMaxRadius = 120

FireEffect = path .. "/effects/rocket_lock_fire.lua"
ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/machinegun_explode.lua"
ReloadEffect = "effects/mortar_reload.lua"
ReloadEffectOffset = -0.5

Projectile = "aarocket"
BarrelLength = 90.0
-- Мин. клиренс: ракета должна успеть отойти от установки,
-- иначе воздушный разрыв (airburst) рвёт её прямо на пусковой.
MinFireClearance = 700
FireClearanceOffsetInner = 20
FireClearanceOffsetOuter = 40
AttractZoomOutDuration = 5

ReloadTime = 2.4
ReloadTimeIncludesBurst = false
RoundsEachBurst = 1
RoundPeriod = 0.20

-- ВАЖНО: ракета намеренно МЕДЛЕННАЯ (см. блок Missile в
-- projectile_list.lua — тяга снижена, доворот ~15G).
-- Скорость вылета из трубы тоже снижена: ракета не «прыгает»,
-- а спокойно выходит и начинает доворачивать.
-- MinFireClearance держит её подальше от установки.
MinFireSpeed = 900.0
MaxFireSpeed = 1500.0
MinFireRadius = 300.0
MaxFireRadius = 8000.0
MinFireAngle = 5
MaxFireAngle = 85
KickbackMean = 20
KickbackStdDev = 3
MouseSensitivityFactor = 0.5
PanDuration = 0
FireStdDev = 0.005
FireStdDevAuto = 0.005

Recoil = 80000
EnergyFireCost = 400.0
MetalFireCost = 40.0

ShowFireAngle = true

BarrelRecoilLimit = -0.15
BarrelRecoilSpeed = -2
BarrelReturnForce = 0.5

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "manpads-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/manpads/base.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "manpads-head",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/manpads/head.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "manpads-barrel",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/manpads/barrel.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    }
}

Root =
{
    Name = "MANPADS",
    Angle = 0,
    Pivot = { 0, -0.55 },
    PivotOffset = { 0, 0 },
    Sprite = "manpads-base",
    UserData = 0,

    ChildrenBehind =
    {
        {
            Name = "Head",
            Angle = 0,
            Pivot = { 0, -0.05 },
            PivotOffset = { 0.05, 0 },
            Sprite = "manpads-head",
            UserData = 50,

            ChildrenBehind =
            {
                {
                    Name = "Barrel",
                    Angle = 0,
                    Pivot = { -0.5, -0.15 },
                    PivotOffset = { 0.5, 0 },
                    Sprite = "manpads-barrel",
                    UserData = 100,

                    ChildrenInFront =
                    {
                        { Name = "Hardpoint0", Angle = 90, Pivot = { 0, 0.05 }, PivotOffset = { 0, 0 } },
                        { Name = "LaserSight", Angle = 90, Pivot = { 0.18, -0.35 }, PivotOffset = { 0, 0 } },
                        { Name = "Chamber", Angle = 0, Pivot = { -0.32, -0.15 }, PivotOffset = { 0, 0 } },
                    },
                },
            },
        },
        { Name = "Icon", Pivot = { 0, 0.5 } },
    },
}

table.insert(Sprites, ButtonSprite("hud-context-ammo-manpads-std", "context/HUD-Ammo-MANPADSStd", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-emp", "context/HUD-Ammo-EMP", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-homing", "context/HUD-Ammo-Homing", nil, nil, nil, nil, path))

dlc2_Ammunition =
{
    {
        StringId = "Weapon.AmmoMANPADSStd",
        Sprite   = "hud-context-ammo-manpads-std",
        Projectile = "aarocket",
        Devices  = { { Name = "ammo_aarocket", Consume = true } },
    },
    {
        StringId = "Weapon.AmmoEMP",
        Sprite   = "hud-context-ammo-emp",
        Projectile = "emprocket",
        Devices  = { { Name = "ammo_emprocket", Consume = true } },
    },
    {
        StringId = "Weapon.AmmoHoming",
        Sprite   = "hud-context-ammo-homing",
        Projectile = "homingrocket",
        EnergyFireCost = 1000.0,
        MetalFireCost = 80.0,
        Devices  = { { Name = "ammo_homingrocket", Consume = true } },
    },
}

