-- ============================================================
--  MP Repair Station: эффект процесса ремонта
--  Движок вызывает его на устройствах/узлах, которые лечит станция.
-- ============================================================
LifeSpan = 0.9

Effects =
{
    {
        Type = "sprite",
        TimeToTrigger = 0.0,
        PlayForEnemy = false,
        LocalPosition = { x = 0, y = 0, z = 0 },
        LocalVelocity = { x = 0, y = 0, z = 0 },
        Acceleration = { x = 0, y = 0, z = 0 },
        Drag = 0.1,
        Sprite = "effects/media/Repair",
        UseOwnerAngle = false,
        Additive = true,
        TimeToLive = 0.6,
        InitialSize = 0.35,
        ExpansionRate = 1.6,
        AngleMaxDeviation = 0,
        AngularVelocity = 0,
        RandomAngularVelocityMagnitude = 0,
        Colour1 = { 150, 240, 190, 200 },
        Colour2 = { 150, 240, 190, 0 },
    },
    {
        Type = "sparks",
        TimeToTrigger = 0.05,
        SparkCount = 8,
        BurstPeriod = 0.1,
        SparksPerBurst = 1,
        LocalPosition = { x = 0, y = 0, z = 10 },
        Sprite = "effects/media/Steam",

        Gravity = 0,

        NormalDistribution =
        {
            Mean = 90,
            StdDev = 30,
        },

        Keyframes =
        {
            {
                Angle = 0,
                RadialOffsetMin = 0,
                RadialOffsetMax = 8,
                ScaleMean = 0.10,
                ScaleStdDev = 0.01,
                SpeedStretch = 0,
                SpeedMean = 26,
                SpeedStdDev = 4,
                Drag = 0.14,
                RotationMean = 0,
                RotationStdDev = 30,
                RotationalSpeedMean = 0,
                RotationalSpeedStdDev = 12,
                AgeMean = 0.55,
                AgeStdDev = 0.02,
                AlphaKeys = { 0.1, 1 },
                ScaleKeys = { 0.1, 0.22 },
                colour = { 200, 255, 220, 220 },
            },
        },
    },
}
