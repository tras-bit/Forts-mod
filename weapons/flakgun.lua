-- ============================================================
--  Military Pack: ЗЕНИТКА ФЛАК (flakgun.lua)
--  Новая модель: тяжелая зенитная спаренная пушка
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

WeaponMass = 190.0
HitPoints = 700.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DeviceSplashDamage = 0.0
DeviceSplashDamageMaxRadius = 380
DeviceSplashDamageDelay = 0.2
IncendiaryRadius = 0.0
IncendiaryRadiusHeated = 0.0
StructureSplashDamage = 0.0
StructureSplashDamageMaxRadius = 140

FireEffect = "effects/flak_fire.lua"
ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/cannon_explode.lua"
ReloadEffect = "effects/cannon_reload.lua"
ReloadEffectOffset = -1.5

Projectile = "flakshell"
BarrelLength = 100.0
MinFireClearance = 500
FireClearanceOffsetInner = 20
FireClearanceOffsetOuter = 40
AttractZoomOutDuration = 5

ReloadTime = 2.8
ReloadTimeIncludesBurst = false
RoundsEachBurst = 2
RoundPeriod = 0.15

TriggerProjectileAgeAction = true
MinAgeTrigger = 0.4
MaxAgeTrigger = 12.0
ShowFireSpeed = false

MinFireSpeed = 7500.0
MaxFireSpeed = 7500.1
MinFireRadius = 400.0
MaxFireRadius = 2400.0
MinFireAngle = -10
MaxFireAngle = 85
KickbackMean = 25
KickbackStdDev = 4
MouseSensitivityFactor = 0.5
PanDuration = 0
FireStdDev = 0.012
FireStdDevAuto = 0.012

Recoil = 140000
EnergyFireCost = 700.0
MetalFireCost = 70.0

ShowFireAngle = true

BarrelRecoilLimit = -0.2
BarrelRecoilSpeed = -2
BarrelReturnForce = 0.5

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "fg-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/flakgun/base.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "fg-head",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/flakgun/head.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "fg-barrel",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/flakgun/barrel.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
}

NodeEffects =
{
    {
        NodeName = "ReloadEmitter",
        EffectPath = "effects/cannon_muzzle_smoke.lua",
        Automatic = false,
    },
}

Root =
{
    Name = "Flakgun",
    Angle = 0,
    Pivot = { 0, -0.57 },
    PivotOffset = { 0, 0 },
    Sprite = "fg-base",
    UserData = 0,

    ChildrenBehind =
    {
        {
            Name = "Head",
            Angle = 0,
            Pivot = { 0, -0.05 },
            PivotOffset = { 0.13, 0 },
            Sprite = "fg-head",
            UserData = 50,

            ChildrenBehind =
            {
                {
                    Name = "Barrel",
                    Angle = 0,
                    Pivot = { -0.5, -0.15 },
                    PivotOffset = { 0.5, 0 },
                    Sprite = "fg-barrel",
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
        {
            Name = "Icon",
            Pivot = { 0, 0.5 },
        },
    },

    ChildrenInFront =
    {
        {
            Name = "ReloadEmitter",
            Angle = 90,
            Pivot = { -0.054, -0.118 },
            PivotOffset = { 0, 0 },
        },
    },
}

table.insert(Sprites, ButtonSprite("hud-context-ammo-flak", "context/HUD-Ammo-Flak", nil, nil, nil, nil, path))

dlc2_Ammunition =
{
    {
        StringId = "Weapon.MPFlakBelt",
        Sprite   = "hud-context-ammo-flak",
        Devices  = { { Name = "ammo_flak", Consume = true } },
    },
}

