-- ============================================================
--  MP Repair Station: эффект активации (вспышка + пар)
-- ============================================================
LifeSpan = 0.9

Effects =
{
    {
        Type = "sparks",
        TimeToTrigger = 0.0,
        SparkCount = 24,
        BurstPeriod = 0.05,
        SparksPerBurst = 1,
        LocalPosition = { x = 0, y = 0, z = 40 },
        Sprite = "effects/media/Steam",

        Gravity = 0,

        NormalDistribution =
        {
            Mean = 90,
            StdDev = 18,
        },

        Keyframes =
        {
            {
                Angle = 0,
                RadialOffsetMin = 0,
                RadialOffsetMax = 24,
                ScaleMean = 0.20,
                ScaleStdDev = 0.02,
                SpeedStretch = 0,
                SpeedMean = 55,
                SpeedStdDev = 6,
                Drag = 0.12,
                RotationMean = 0,
                RotationStdDev = 45,
                RotationalSpeedMean = 0,
                RotationalSpeedStdDev = 16,
                AgeMean = 0.8,
                AgeStdDev = 0.02,
                AlphaKeys = { 0.1, 1 },
                ScaleKeys = { 0.1, 0.2 },
                colour = { 210, 240, 255, 255 },
            },
        },
    },
    {
        Type = "sprite",
        TimeToTrigger = 0.0,
        PlayForEnemy = false,
        LocalPosition = { x = 0, y = 0, z = 0 },
        Sprite = "effects/media/Repair",
        UseOwnerAngle = false,
        Additive = true,
        TimeToLive = 0.35,
        InitialSize = 0.6,
        ExpansionRate = 22,
        Colour1 = { 160, 230, 255, 200 },
        Colour2 = { 160, 230, 255, 0 },
    },
}
