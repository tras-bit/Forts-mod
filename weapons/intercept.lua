-- ============================================================
--  ЗРК-ПЕРЕХВАТЧИК (intercept) — самостоятельный конфиг (v1.43)
--  Противоракетная точка: залп СТРОГО из 2 ракет-перехватчиков
--  Башня и пусковая подняты выше
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

WeaponMass = 160.0
HitPoints = 550.0
EnergyProductionRate = 0.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 1
MaxWindHeight = 0
MaxRotationalSpeed = 0
DeviceSplashDamage = 120
DeviceSplashDamageMaxRadius = 350
DeviceSplashDamageDelay = 0.2
IncendiaryRadius = 100
IncendiaryRadiusHeated = 130
StructureSplashDamage = 160
StructureSplashDamageMaxRadius = 130

FireEffect = path .. "/effects/mpsam_salvo.lua"
ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyEffect = "effects/machinegun_explode.lua"
ReloadEffect = "effects/minigun_reload.lua"
ReloadEffectOffset = -0.5

Projectile = "interceptmissile"
BarrelLength = 110.0
MinFireClearance = 700
FireClearanceOffsetInner = 20
FireClearanceOffsetOuter = 40
AttractZoomOutDuration = 5

ReloadTime = 2.5
ReloadTimeIncludesBurst = false
RoundsEachBurst = 2
RoundPeriod = 0.25

MinFireSpeed = 9000.0
MaxFireSpeed = 9000.1
MinFireRadius = 300.0
MaxFireRadius = 1600.0
MinFireAngle = 5
MaxFireAngle = 85
KickbackMean = 25
KickbackStdDev = 6
MouseSensitivityFactor = 0.5
PanDuration = 0
FireStdDev = 0.010
FireStdDevAuto = 0.012

Recoil = 120000
EnergyFireCost = 300.0
MetalFireCost = 30.0

ShowFireAngle = true

BarrelRecoilLimit = -0.2
BarrelRecoilSpeed = -2
BarrelReturnForce = 0.5

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
    {
        Name = "intercept-base",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/intercept/base.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "intercept-head",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/intercept/head.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    },
    {
        Name = "intercept-barrel",
        States =
        {
            Normal = { Frames = { { texture = path .. "/weapons/media/intercept/barrel.png" }, mipmap = true, }, },
            Idle = Normal,
        },
    }
}

Root =
{
    Name = "Intercept",
    Angle = 0,
    Pivot = { 0, -0.55 },
    PivotOffset = { 0, 0 },
    Sprite = "intercept-base",
    UserData = 0,

    ChildrenBehind =
    {
        {
            Name = "Head",
            Angle = 45,
            Pivot = { 0, -0.22 },       -- поднята выше на 1.0
            PivotOffset = { 0.05, 0 },
            Sprite = "intercept-head",
            UserData = 50,

            ChildrenBehind =
            {
                {
                    Name = "Barrel",
                    Angle = 0,
                    Pivot = { -0.5, -0.15 },
                    PivotOffset = { 0.5, 0 },
                    Sprite = "intercept-barrel",
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

table.insert(Sprites, ButtonSprite("hud-context-ammo-intercept", "context/HUD-Ammo-ZRK2", nil, nil, nil, nil, path))

dlc2_Ammunition =
{
    {
        StringId = "Weapon.MPIntercept",
        Sprite   = "hud-context-ammo-intercept",
        Devices  = { { Name = "ammo_sam", Consume = true } },
    },
}

