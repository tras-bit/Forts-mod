-- ============================================================
--  Military Pack: ТЯЖЁЛАЯ ПУШКА ТАЙФУН (typhoon.lua)
--  Новая модель: суперпушка, поднята выше над станиной
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

WeaponMass = 320.0
HitPoints = 1200.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DeviceSplashDamage = 250
DeviceSplashDamageMaxRadius = 550
DeviceSplashDamageDelay = 0.2
IncendiaryRadius = 180
IncendiaryRadiusHeated = 240
StructureSplashDamage = 300
StructureSplashDamageMaxRadius = 240

FireEffect = "effects/cannon_fire.lua"
ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/cannon_explode.lua"
ReloadEffect = "effects/cannon_reload.lua"
ReloadEffectOffset = -1.5

Projectile = "typhoonshell"
BarrelLength = 110.0
MinFireClearance = 500
FireClearanceOffsetInner = 20
FireClearanceOffsetOuter = 40
AttractZoomOutDuration = 5

ReloadTime = 6.0
ReloadTimeIncludesBurst = false
RoundsEachBurst = 1

TriggerProjectileAgeAction = true
MinAgeTrigger = 0.4
MaxAgeTrigger = 12.0
ShowFireSpeed = false
RoundPeriod = 0.20

MinFireSpeed = 8000.0
MaxFireSpeed = 8000.1
MinFireRadius = 500.0
MaxFireRadius = 2800.0
MinFireAngle = -15
MaxFireAngle = 80
KickbackMean = 45
KickbackStdDev = 6
MouseSensitivityFactor = 0.5
PanDuration = 0
FireStdDev = 0.015
FireStdDevAuto = 0.015

Recoil = 350000
EnergyFireCost = 2500.0
MetalFireCost = 250.0

ShowFireAngle = true

BarrelRecoilLimit = -0.2
BarrelRecoilSpeed = -2
BarrelReturnForce = 0.5

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "typhoon-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/typhoon/base.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "typhoon-head",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/typhoon/head.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "typhoon-barrel",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/typhoon/barrel.png" }, mipmap = true, }, },
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
    Name = "Typhoon",
    Angle = 0,
    Pivot = { 0, -0.57 },
    PivotOffset = { 0, 0 },
    Sprite = "typhoon-base",
    UserData = 0,

    ChildrenBehind =
    {
        {
            Name = "Head",
            Angle = 0,
            Pivot = { 0, -0.15 },       -- поднята выше над станиной
            PivotOffset = { 0.13, 0 },
            Sprite = "typhoon-head",
            UserData = 50,

            ChildrenBehind =
            {
                {
                    Name = "Barrel",
                    Angle = 0,
                    Pivot = { -0.5, -0.15 },
                    PivotOffset = { 0.5, 0 },
                    Sprite = "typhoon-barrel",
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

table.insert(Sprites, ButtonSprite("hud-context-ammo-typhoon", "context/HUD-Ammo-Typhoon", nil, nil, nil, nil, path))

dlc2_Ammunition =
{
    {
        StringId = "Weapon.MPTyphoon",
        Sprite   = "hud-context-ammo-typhoon",
        Devices  = { { Name = "ammo_typhoon", Consume = true } },
    },
}

