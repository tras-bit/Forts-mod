-- ============================================================
--  КАССЕТНАЯ ПУШКА М1 — детальная конфигурация оружия
-- ============================================================

dofile("ui/uihelper.lua")

Scale = 1
SelectionWidth = 95.0
SelectionHeight = 60.0
SelectionOffset = { -18, -60.5 }
RecessionBox =
{
    Size = { 200, 25 },
    Offset = { -300, -70 },
}
CanFlip = false

WeaponMass = 160.0
HitPoints = 600.0
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

FireEffect = "effects/fire_cannon.lua"
ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/cannon_explode.lua"
DestroyUnderwaterEffect = "mods/dlc2/effects/device_explode_submerged_large.lua"
ShellEffect = "effects/shell_eject_cannon.lua"
ReloadEffect = "effects/reload_cannon.lua"
ReloadEffectOffset = -1.5

-- Снаряд ПО УМОЛЧАНИЮ: ванильный фугас 155мм (летит без раннего подрыва)
Projectile = "cannon"

BarrelLength = 100.0
MinFireClearance = 1000
FireClearanceOffsetInner = 20
FireClearanceOffsetOuter = 40
AttractZoomOutDuration = 5

ReloadTime = 20.0
ReloadTimeIncludesBurst = false
RoundsEachBurst = 1

TriggerProjectileAgeAction = true
MinAgeTrigger = 0.4
MaxAgeTrigger = 12.0

ShowFireSpeed = false
DisruptionBlocksFire = true

MinFireSpeed = 6000.0
MaxFireSpeed = 6000.1
MinFireRadius = 600.0
MaxFireRadius = 1200.0
MinFireAngle = -20
MaxFireAngle = 30
KickbackMean = 60
KickbackStdDev = 8
MouseSensitivityFactor = 0.5
PanDuration = 0

FireStdDev = 0.005
FireStdDevAuto = 0.008

Recoil = 600000
EnergyFireCost = 2000.0
MetalFireCost = 80.0

ShowFireAngle = true

BarrelRecoilLimit = -0.25
BarrelRecoilSpeed = -2
BarrelReturnForce = 0.5

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "cc-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/clustercannon/base.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "cc-head",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/clustercannon/head.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "cc-barrel",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/clustercannon/barrel.png" }, mipmap = true, }, },
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
    Name = "Cannon",
    Angle = 0,
    Pivot = { 0, -0.57 },
    PivotOffset = { 0, 0 },
    Sprite = "cc-base",
    UserData = 0,

    ChildrenBehind =
    {
        {
            Name = "Head",
            Angle = 0,
            Pivot = { 0, -0.05 },
            PivotOffset = { 0.13, 0 },
            Sprite = "cc-head",
            UserData = 50,

            ChildrenBehind =
            {
                {
                    Name = "Barrel",
                    Angle = 0,
                    Pivot = { -0.5, -0.15 },
                    PivotOffset = { 0.5, 0 },
                    Sprite = "cc-barrel",
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

                    ChildrenBehind =
                    {
                        {
                            Name = "ReloadEmitter",
                            Angle = 90,
                            Pivot = { 0.45, 0 },
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
        Devices  = { { Name = "ammo_he", Consume = true } },
    },
    {
        StringId = "Weapon.MPCluster",
        Sprite   = "hud-context-ammo-cluster",
        Projectile = "clustershell",
        MinFireSpeed = 6000.0,
        MaxFireSpeed = 6000.1,
        EnergyFireCost = 2500.0,
        MetalFireCost = 120.0,
        Devices  = { { Name = "ammo_cluster", Consume = true } },
    },
    {
        StringId = "Weapon.MPClusterHEAT",
        Sprite   = "hud-context-ammo-heat",
        Projectile = "heat_shell",
        MinFireSpeed = 6000.0,
        MaxFireSpeed = 6000.1,
        EnergyFireCost = 2500.0,
        MetalFireCost = 120.0,
        Devices  = { { Name = "ammo_heat", Consume = true } },
    },
    {
        StringId = "Weapon.MPClusterAP",
        Sprite   = "hud-context-ammo-ap",
        Projectile = "ap_shell",
        MinFireSpeed = 7000.0,
        MaxFireSpeed = 7000.1,
        EnergyFireCost = 2500.0,
        MetalFireCost = 120.0,
        Devices  = { { Name = "ammo_ap", Consume = true } },
    },
}

