-- ============================================================
--  Military Pack: ШРАПНЕЛЬ 20ММ (shrapnel20.lua)
--  Новая модель: тяжелая шестиствольная автопушка
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

WeaponMass = 180.0
HitPoints = 650.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DeviceSplashDamage = 130
DeviceSplashDamageMaxRadius = 380
DeviceSplashDamageDelay = 0.2
IncendiaryRadius = 100
IncendiaryRadiusHeated = 140
StructureSplashDamage = 160
StructureSplashDamageMaxRadius = 140

FireEffect = "effects/minigun_fire.lua"
ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/cannon_explode.lua"
ReloadEffect = "effects/cannon_reload.lua"
ReloadEffectOffset = -1.5

Projectile = "shrapnelshell"
BarrelLength = 100.0
MinFireClearance = 500
FireClearanceOffsetInner = 20
FireClearanceOffsetOuter = 40
AttractZoomOutDuration = 5

ReloadTime = 3.5
ReloadTimeIncludesBurst = false
RoundsEachBurst = 3
RoundPeriod = 0.15

TriggerProjectileAgeAction = true
MinAgeTrigger = 0.4
MaxAgeTrigger = 12.0
ShowFireSpeed = false

MinFireSpeed = 9000.0
MaxFireSpeed = 9000.1
MinFireRadius = 400.0
MaxFireRadius = 2400.0
MinFireAngle = -15
MaxFireAngle = 80
KickbackMean = 25
KickbackStdDev = 4
MouseSensitivityFactor = 0.5
PanDuration = 0
FireStdDev = 0.012
FireStdDevAuto = 0.012

Recoil = 160000
EnergyFireCost = 800.0
MetalFireCost = 80.0

ShowFireAngle = true

BarrelRecoilLimit = -0.2
BarrelRecoilSpeed = -3
BarrelReturnForce = 0.5

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "sp20-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/shrapnel20/base.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "sp20-head",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/shrapnel20/head.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "sp20-barrel",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/shrapnel20/barrel.png" }, mipmap = true, }, },
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
    Name = "Shrapnel20",
    Angle = 0,
    Pivot = { 0, -0.57 },
    PivotOffset = { 0, 0 },
    Sprite = "sp20-base",
    UserData = 0,

    ChildrenBehind =
    {
        {
            Name = "Head",
            Angle = 0,
            Pivot = { 0, -0.05 },
            PivotOffset = { 0.13, 0 },
            Sprite = "sp20-head",
            UserData = 50,

            ChildrenBehind =
            {
                {
                    Name = "Barrel",
                    Angle = 0,
                    Pivot = { -0.5, -0.15 },
                    PivotOffset = { 0.5, 0 },
                    Sprite = "sp20-barrel",
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

table.insert(Sprites, ButtonSprite("hud-context-ammo-solid20", "context/HUD-Ammo-Solid20", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-shrapnel", "context/HUD-Ammo-Shrapnel", nil, nil, nil, nil, path))

dlc2_Ammunition =
{
    {
        StringId = "Weapon.MP20Solid",
        Sprite   = "hud-context-ammo-solid20",
        Devices  = { { Name = "ammo_solid20", Consume = true } },
    },
    {
        StringId = "Weapon.MP20Shrapnel",
        Sprite   = "hud-context-ammo-shrapnel",
        Devices  = { { Name = "ammo_shrapnel", Consume = true } },
    },
}

