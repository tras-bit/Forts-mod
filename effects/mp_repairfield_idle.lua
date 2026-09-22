-- ============================================================
--  MP Repair Station: стойкий ореол зоны ремонта (idle)
-- ============================================================
LifeSpan = 1.0

Sprites =
{
    {
        Name = "mp-repairfield-idle",
        States =
        {
            Normal =
            {
                Frames =
                {
                    { texture = "effects/media/Repair.dds", colour = { 1, 1, 1, 0.10 }, duration = 1.0 },
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
        Sprite = "mp-repairfield-idle",
        KillParticleOnEffectCancel = true,
        KillParticleOnEffectExpire = true,
        Additive = false,
        TimeToLive = 10000000,
        InitialSize = 3.1,
        ExpansionRate = 0,
        AngleMaxDeviation = 0,
        AngularVelocity = 0,
        RandomAngularVelocityMagnitude = 0,
        Colour1 = { 90, 180, 210, 26 },
        Colour2 = { 90, 180, 210, 0 },
    },
}
