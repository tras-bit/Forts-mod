-- ============================================================
--  Military Pack: REMOTE REPAIR STATION (стиль мода, v4.7)
--  Переработка мода repair_station: новая модель, новые иконки,
--  та же механика (ремонт + тушение + отчистка дыма в радиусе).
--    RepairFieldRadius  — радиус действия
--    RepairFieldPeriod  — период срабатывания (сек)
--    RepairEffect       — эффект восстановления
--    ActivateEffect / DeactivateEffect — включение/выключение
--  Плюс собственные анимации рук: repair_anim, extinguisher_anim,
--  и вращающийся радар-маяк (sign_anim).
-- ============================================================

ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyUnderwaterEffect = "mods/dlc2/effects/device_explode_submerged.lua"

Scale = 1
SelectionWidth = 46.0
SelectionHeight = 34.0
SelectionOffset = { 0.0, -38.0 }
Mass = 42.0
HitPoints = 70
EnergyProductionRate = -12
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0
MinWindEfficiency = 0
MaxWindHeight = 0
MaxRotationalSpeed = 0
IgnitePlatformOnDestruct = true

-- --- ядро механики ремонтной станции ---
DisruptClearRadius = 700
DisruptClearRate = 30
RepairFieldRadius = 280
RepairFieldPeriod = 1
RepairEffect = path .. "/effects/mp_repairfield_repair.lua"
ActivateEffect = path .. "/effects/mp_repairfield_activate.lua"
DeactivateEffect = path .. "/effects/mp_repairfield_deactivate.lua"

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

-- ------------------------------------------------------------
--  Спрайты: одна общая база + две руки + маяк
--  Все текстуры — 256x128, нарисованы в стиле мода.
-- ------------------------------------------------------------
local MP_BASE = path .. "/devices/media/repairstation_mp.png"

Sprites =
{
    {
        Name = "mp-repairstation-base",
        States =
        {
            Normal = { Frames = { { texture = MP_BASE }, mipmap = true, }, },
            Idle   = { Frames = { { texture = MP_BASE }, mipmap = true, }, },
            Active = { Frames = { { texture = MP_BASE }, mipmap = true, }, },
        },
    },
    {
        -- маяк-радар: три кадра вращения
        Name = "mp-rs-beacon",
        States =
        {
            Normal = { Frames = { { texture = path .. "/devices/repairstation_mp/beacon_0.dds" }, mipmap = true, }, },
            Activate =
            {
                Frames =
                {
                    { texture = path .. "/devices/repairstation_mp/beacon_0.dds" },
                    { texture = path .. "/devices/repairstation_mp/beacon_1.dds" },
                    { texture = path .. "/devices/repairstation_mp/beacon_2.dds" },
                    { texture = path .. "/devices/repairstation_mp/beacon_3.dds" },
                    duration = 0.12,
                    blendColour = false,
                    blendCoordinates = false,
                    mipmap = true,
                },
                NextState = "Active",
            },
            Active =
            {
                Frames =
                {
                    { texture = path .. "/devices/repairstation_mp/beacon_0.dds" },
                    { texture = path .. "/devices/repairstation_mp/beacon_1.dds" },
                    { texture = path .. "/devices/repairstation_mp/beacon_2.dds" },
                    { texture = path .. "/devices/repairstation_mp/beacon_3.dds" },
                    duration = 0.12,
                    blendColour = false,
                    blendCoordinates = false,
                    mipmap = true,
                },
                NextState = "Active",
            },
            Deactivate = { Frames = { { texture = path .. "/devices/repairstation_mp/beacon_0.dds" }, mipmap = true, }, NextState = "Normal" },
        },
    },
    {
        -- ремонтная рука
        Name = "mp-rs-repairarm",
        States =
        {
            Normal = { Frames = { { texture = path .. "/devices/repairstation_mp/repairarm_0.dds" }, mipmap = true, }, },
            Activate =
            {
                Frames =
                {
                    { texture = path .. "/devices/repairstation_mp/repairarm_0.dds" },
                    { texture = path .. "/devices/repairstation_mp/repairarm_1.dds" },
                    { texture = path .. "/devices/repairstation_mp/repairarm_2.dds" },
                    duration = 0.08,
                    mipmap = true,
                },
                NextState = "Active",
            },
            Active =
            {
                Frames =
                {
                    { texture = path .. "/devices/repairstation_mp/repairarm_0.dds" },
                    { texture = path .. "/devices/repairstation_mp/repairarm_1.dds" },
                    { texture = path .. "/devices/repairstation_mp/repairarm_2.dds" },
                    duration = 0.18,
                    mipmap = true,
                },
                NextState = "Active",
            },
            Deactivate = { Frames = { { texture = path .. "/devices/repairstation_mp/repairarm_0.dds" }, mipmap = true, }, NextState = "Normal" },
        },
    },
    {
        -- рука-огнетушитель
        Name = "mp-rs-extarm",
        States =
        {
            Normal = { Frames = { { texture = path .. "/devices/repairstation_mp/extarm_0.dds" }, mipmap = true, }, },
            Activate = { Frames = { { texture = path .. "/devices/repairstation_mp/extarm_0.dds" }, duration = 0.2, mipmap = true, }, NextState = "Active" },
            Active = { Frames = { { texture = path .. "/devices/repairstation_mp/extarm_0.dds" }, mipmap = true, }, },
            Deactivate = { Frames = { { texture = path .. "/devices/repairstation_mp/extarm_0.dds" }, duration = 0.2, mipmap = true, }, NextState = "Normal" },
        },
    },
}

-- ------------------------------------------------------------
--  Узловые эффекты (зона ремонта / тушения)
-- ------------------------------------------------------------
NodeEffects =
{
    {
        NodeName = "Idle",
        EffectPath = path .. "/effects/mp_repairfield_idle.lua",
        Automatic = false,
    },
    {
        NodeName = "Active",
        EffectPath = path .. "/effects/mp_repairfield_active.lua",
        Automatic = false,
    },
    {
        NodeName = "Extinguish",
        EffectPath = path .. "/effects/mp_repairfield_extinguish.lua",
        Automatic = false,
    },
}

Root =
{
    Name = "RepairStationMP",
    Angle = 0,
    Pivot = { 0, -0.26 },
    PivotOffset = { 0, 0 },
    Sprite = "mp-repairstation-base",

    ChildrenInFront =
    {
        {
            Name = "sign",
            Angle = 0,
            Pivot = { -0.02, -0.16 },
            PivotOffset = { 0, 0 },
            Sprite = "mp-rs-beacon",
            UserData = 40,
        },
        { Name = "Idle", Angle = 0, Pivot = { 0, 0 }, PivotOffset = { 0, 0 } },
        { Name = "Active", Angle = 0, Pivot = { 0, 0 }, PivotOffset = { 0, 0 } },
        { Name = "Extinguish", Angle = 0, Pivot = { 0.6, 0 }, PivotOffset = { 0, 0 } },
    },

    ChildrenBehind =
    {
        {
            Name = "repair_arm",
            Angle = 0,
            Pivot = { -0.46, 0.02 },
            PivotOffset = { 0, 0 },
            Sprite = "mp-rs-repairarm",
            UserData = 60,
        },
        {
            Name = "extinguisher_arm",
            Angle = 0,
            Pivot = { 0.48, 0.04 },
            PivotOffset = { 0, 0 },
            Sprite = "mp-rs-extarm",
            UserData = 80,
        },
    },
}
