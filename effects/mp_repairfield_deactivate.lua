-- ============================================================
--  MP Repair Station: эффект деактивации (затухание)
-- ============================================================
LifeSpan = 0.6

Effects =
{
    {
        Type = "sprite",
        TimeToTrigger = 0.0,
        PlayForEnemy = false,
        LocalPosition = { x = 0, y = 0, z = 0 },
        Sprite = "effects/media/Repair",
        UseOwnerAngle = false,
        Additive = true,
        TimeToLive = 0.4,
        InitialSize = 1.4,
        ExpansionRate = -3,
        Colour1 = { 120, 170, 200, 120 },
        Colour2 = { 120, 170, 200, 0 },
    },
}
