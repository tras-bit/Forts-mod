-- ============================================================
--  MP Repair Station: эффект зоны ремонта (пульсирующий купол)
-- ============================================================
LifeSpan = 1.2

Sprites =
{
    {
        Name = "mp-repairfield-active",
        States =
        {
            Normal =
            {
                Frames =
                {
                    { texture = "effects/media/Repair.dds", colour = { 1, 1, 1, 0.0 }, duration = 0.4 },
                    { texture = "effects/media/Repair.dds", colour = { 1, 1, 1, 0.85 }, duration = 0.4 },
                    { texture = "effects/media/Repair.dds", colour = { 1, 1, 1, 0.25 }, duration = 0.4 },
                    blendColour = true,
                    mipmap = true,
                },
            },
        },
    },
}

Effects =
{
    {
        Type = "sprite",
        TimeToTrigger = 0,
        PlayForEnemy = false,
        LocalPosition = { x = 0, y = 0, z = 0 },
        LocalVelocity = { x = 0, y = 0, z = 0 },
        Acceleration = { x = 0, y = 0, z = 0 },
        Drag = 0.01,
        Sprite = "mp-repairfield-active",
        KillParticleOnEffectCancel = true,
        KillParticleOnEffectExpire = true,
        Additive = false,
        TimeToLive = 10000000,
        InitialSize = 3.0,
        ExpansionRate = 0,
        AngleMaxDeviation = 0,
        AngularVelocity = 0,
        RandomAngularVelocityMagnitude = 0,
        Colour1 = { 120, 220, 255, 44 },
        Colour2 = { 120, 220, 255, 0 },
    },
}
