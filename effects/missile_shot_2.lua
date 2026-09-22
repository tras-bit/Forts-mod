-- ============================================================
--  ЗРК: звук пуска, вариант 2
--  Было Volume = 1.0 при сэмпле почти в 0 dBFS -> «пизда ушам».
--  Стало 0.30 + затухание по расстоянию (FalloffStart/End).
-- ============================================================
LifeSpan = 2.0

Effects =
{
    {
        Type = "sound",
        Sound = path .. "/audio/sam_shot_2.ogg",
        TimeToTrigger = 0,
        PlayForEnemy = true,
        Volume = 0.30,      -- было 1.0
        Priority = 112,
        Falloff = true,
        FalloffStart = 1500,
        FalloffEnd = 6000,
    },
}
