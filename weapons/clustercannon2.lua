-- ============================================================
--  Military Pack: ПУШКА М2 (ТЯЖЁЛАЯ СПАРКА, clustercannon2.lua)
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

WeaponMass = 240.0
HitPoints = 900.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DeviceSplashDamage = 160
DeviceSplashDamageMaxRadius = 450
DeviceSplashDamageDelay = 0.2
IncendiaryRadius = 140
IncendiaryRadiusHeated = 180
StructureSplashDamage = 200
StructureSplashDamageMaxRadius = 180

FireEffect = "effects/fire_cannon.lua"
ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/cannon_explode.lua"
DestroyUnderwaterEffect = "mods/dlc2/effects/device_explode_submerged_large.lua"
ReloadEffect = "effects/reload_cannon.lua"
ReloadEffectOffset = -1.5

-- Снаряд ПО УМОЛЧАНИЮ: ванильный фугас 155мм (летит без раннего подрыва)
Projectile = "cannon"

BarrelLength = 100.0
MinFireClearance = 1000
FireClearanceOffsetInner = 20
FireClearanceOffsetOuter = 40
AttractZoomOutDuration = 5

ReloadTime = 24.0
ReloadTimeIncludesBurst = false
RoundsEachBurst = 2
RoundPeriod = 0.40

TriggerProjectileAgeAction = true
MinAgeTrigger = 0.4
MaxAgeTrigger = 12.0

ShowFireSpeed = false
DisruptionBlocksFire = true

MinFireSpeed = 6500.0
MaxFireSpeed = 6500.1
MinFireRadius = 600.0
MaxFireRadius = 1400.0
MinFireAngle = -20
MaxFireAngle = 35
KickbackMean = 80
KickbackStdDev = 10
MouseSensitivityFactor = 0.5
PanDuration = 0

FireStdDev = 0.005
FireStdDevAuto = 0.008

Recoil = 700000
EnergyFireCost = 3000.0
MetalFireCost = 160.0

ShowFireAngle = true

BarrelRecoilLimit = -0.25
BarrelRecoilSpeed = -2
BarrelReturnForce = 0.5

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "cc2-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/clustercannon2/base.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "cc2-head",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/clustercannon2/head.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "cc2-barrel",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/clustercannon2/barrel.png" }, mipmap = true, }, },
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
    Name = "CannonMk2",
    Angle = 0,
    Pivot = { 0, -0.57 },
    PivotOffset = { 0, 0 },
    Sprite = "cc2-base",
    UserData = 0,

    ChildrenBehind =
    {
        {
            Name = "Head",
            Angle = 0,
            Pivot = { 0, -0.05 },
            PivotOffset = { 0.13, 0 },
            Sprite = "cc2-head",
            UserData = 50,

            ChildrenBehind =
            {
                {
                    Name = "Barrel",
                    Angle = 0,
                    Pivot = { -0.5, -0.15 },
                    PivotOffset = { 0.5, 0 },
                    Sprite = "cc2-barrel",
                    UserData = 100,

                    ChildrenInFront =
                    {
                        {
                            Name = "Hardpoint0",
                            Angle = 90,
                            Pivot = { 0, 0.05 },
                            PivotOffset = { 0, 0 },
                        },
                        {
                            Name = "LaserSight",
                            Angle = 90,
                            Pivot = { 0.18, -0.35 },
                            PivotOffset = { 0, 0 },
                        },
                        {
                            Name = "Chamber",
                            Angle = 0,
                            Pivot = { -0.32, -0.15 },
                            PivotOffset = { 0, 0 },
                        },
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

table.insert(Sprites, ButtonSprite("hud-context-ammo-plain", "context/HUD-Ammo-Plain", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-cluster", "context/HUD-Ammo-Cluster", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-heat", "context/HUD-Ammo-Heat", nil, nil, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-context-ammo-ap", "context/HUD-Ammo-AP", nil, nil, nil, nil, path))

dlc2_Ammunition =
{
    {
        StringId = "Weapon.MPCannonHE",
        Sprite   = "hud-context-ammo-plain",
        ReloadTime = 22.0,
        RoundsEachBurst = 2,
        RoundPeriod = 0.40,
        Devices  = { { Name = "ammo_he", Consume = true } },
    },
    {
        StringId = "Weapon.MPCluster",
        Sprite   = "hud-context-ammo-cluster",
        Projectile = "clustershell2",
        RoundsEachBurst = 2,
        RoundPeriod = 0.40,
        MinFireSpeed = 6500.0,
        MaxFireSpeed = 6500.1,
        EnergyFireCost = 4000.0,
        MetalFireCost = 220.0,
        Devices  = { { Name = "ammo_cluster", Consume = true } },
    },
    {
        StringId = "Weapon.MPClusterHEAT",
        Sprite   = "hud-context-ammo-heat",
        Projectile = "heat_shell2",
        RoundsEachBurst = 2,
        RoundPeriod = 0.40,
        MinFireSpeed = 6500.0,
        MaxFireSpeed = 6500.1,
        EnergyFireCost = 4000.0,
        MetalFireCost = 220.0,
        Devices  = { { Name = "ammo_heat", Consume = true } },
    },
    {
        StringId = "Weapon.MPClusterAP",
        Sprite   = "hud-context-ammo-ap",
        Projectile = "ap_shell2",
        RoundsEachBurst = 2,
        RoundPeriod = 0.40,
        MinFireSpeed = 7500.0,
        MaxFireSpeed = 7500.1,
        EnergyFireCost = 4000.0,
        MetalFireCost = 220.0,
        Devices  = { { Name = "ammo_ap", Consume = true } },
    },
}

