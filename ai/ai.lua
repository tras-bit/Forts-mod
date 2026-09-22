-- ============================================================
--  Military Pack: автоматическое ПВО + ИИ (v2.1)
--  v2.1: ТОЛЬКО intercept — автоматическое ПВО с идеальным
--  наведением. ЗРК отключён от автоматического ПВО.
-- ============================================================

if Balance == nil then Balance = function(a) return a end end

local function RegAA(w, errA, errB, pA, pB)
    if data == nil then return end
    if data.AntiAirErrorStdDev then
        data.AntiAirErrorStdDev[w] = Balance(errA, errB)
    end
    if data.AntiAirFireProbability then
        data.AntiAirFireProbability[w] = Balance(pA, pB)
    end
    if AntiAirFireProbabilityHumanAssist and data.AntiAirFireProbability then
        AntiAirFireProbabilityHumanAssist[w] = data.AntiAirFireProbability[w]
    end
end

-- ПВО-ПЕРЕХВАТЧИК: идеальное наведение (0 разброса, 100% огонь)
RegAA("intercept", 0, 0, 1.0, 1.0)

if data then
    if data.AntiAirOpenDoor then
        data.AntiAirOpenDoor["intercept"] = {
            ["mortar"]      = true,
            ["mortar2"]     = true,
            ["rocket"]      = true,
            ["rocketemp"]   = true,
            ["missile"]     = true,
            ["missile2"]    = true,
            ["howitzer"]    = true,
            ["cannon"]      = true,
            ["flaminghowitzer"] = true,
            ["clustershell"] = true,
            ["heat_shell"]   = true,
            ["ap_shell"]     = true,
            ["aarocket"]     = true,
            ["aamissile"]    = true,
            ["emprocket"]    = true,
            ["shrapnelshell"] = true,
        }
    end
    
    if data.OffensiveFireProbability == nil then data.OffensiveFireProbability = {} end
    data.OffensiveFireProbability["zrk"] = Balance(0.4, 0.6)
    data.OffensiveFireProbability["manpads"] = Balance(0.3, 0.5)
    data.OffensiveFireProbability["shrapnel20"] = Balance(0.5, 0.8)
    data.OffensiveFireProbability["clustercannon"] = Balance(0.4, 0.7)
    
    if data.FireDuringRebuildProbability == nil then data.FireDuringRebuildProbability = {} end
    data.FireDuringRebuildProbability["shrapnel20"] = Balance(0.5, 0.8)
    data.FireDuringRebuildProbability["clustercannon"] = Balance(0.4, 0.7)
end

if AntiAirMaxRanges == nil then AntiAirMaxRanges = {} end
AntiAirMaxRanges["intercept"] = 40000

if ShootableProjectile == nil then ShootableProjectile = {} end
ShootableProjectile["mortar"]           = true
ShootableProjectile["mortar2"]          = true
ShootableProjectile["rocket"]           = true
ShootableProjectile["rocketemp"]        = true
ShootableProjectile["missile"]          = true
ShootableProjectile["missile2"]         = true
ShootableProjectile["howitzer"]         = true
ShootableProjectile["flaminghowitzer"]  = true
ShootableProjectile["cannon"]           = true
ShootableProjectile["clustershell"]  = true
ShootableProjectile["heat_shell"]    = true
ShootableProjectile["ap_shell"]      = true
ShootableProjectile["aarocket"]      = true
ShootableProjectile["aamissile"]     = true
ShootableProjectile["emprocket"]     = true
ShootableProjectile["shrapnelshell"] = true