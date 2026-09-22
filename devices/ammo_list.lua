table.insert(Sprites, ButtonSprite("hud-ammo-typhoon-icon", "context/HUD-Ammo-Typhoon", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, DetailSprite("hud-detail-ammo-typhoon", "HUD-Details-Ammo-Typhoon", path))
-- ============================================================
--  Military Pack: боеприпасы (ammo_list.lua)
-- ============================================================

dofile("ui/uihelper.lua")
dofile("scripts/type.lua")

if BuildQueueConcurrent == nil then BuildQueueConcurrent = {} end
BuildQueueConcurrent["mp_ammo"] = { Default = 2, Min = 1, Max = 2 }

table.insert(Sprites, ButtonSprite("hud-ammo-he-icon", "context/HUD-Ammo-Plain", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-solid20-icon", "context/HUD-Ammo-Solid20", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-shrapnel-icon", "context/HUD-Ammo-Shrapnel", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-flak-icon", "context/HUD-Ammo-Flak", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-cluster-icon", "context/HUD-Ammo-Cluster", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-heat-icon", "context/HUD-Ammo-Heat", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-ap-icon", "context/HUD-Ammo-AP", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-aarocket-icon", "context/HUD-Ammo-MANPADSStd", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-emprocket-icon", "context/HUD-Ammo-EMP", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-homing-icon", "context/HUD-Ammo-Homing", nil, ButtonSpriteBottom, nil, nil, path))
table.insert(Sprites, ButtonSprite("hud-ammo-sam-icon", "context/HUD-Ammo-ZRK2", nil, ButtonSpriteBottom, nil, nil, path))

table.insert(Sprites, DetailSprite("hud-detail-ammo-shells", "HUD-Details-ClusterCannon", path))
table.insert(Sprites, DetailSprite("hud-detail-ammo-20mm", "HUD-Details-SHRAPNEL20", path))
table.insert(Sprites, DetailSprite("hud-detail-ammo-flak", "HUD-Details-FLAKGUN", path))
table.insert(Sprites, DetailSprite("hud-detail-ammo-manpads", "HUD-Details-MANPADS", path))
table.insert(Sprites, DetailSprite("hud-detail-ammo-sam", "HUD-Details-ZRK", path))

if Devices == nil then Devices = {} end

local function Ammo(saveName, icon, detail, metal, energy, buildTime)
    return
    {
        SaveName              = saveName,
        dlc2_BuildQueue       = "mp_ammo",
        FileName              = path .. "/devices/ammocrates.lua",
        Icon                  = icon,
        Detail                = detail,
        Enabled               = true,
        dlc2_BuildAnywhere    = false,
        BuildOnGroundOnly     = false,
        Prerequisite          = "mpfactory",
        BuildTimeIntermediate = buildTime * 0.4,
        BuildTimeComplete     = buildTime,
        ScrapPeriod           = 1,
        MetalCost             = metal,
        EnergyCost            = energy,
        BracingCost           = math.floor(metal * 0.3),
        MetalRepairCost       = 50,
        EnergyRepairCost      = 300,
        MaxUpAngle            = StandardMaxUpAngle,
        SelectEffect          = "ui/hud/devices/ui_devices",
        Flammable             = false,
    }
end

table.insert(Devices, Ammo("ammo_he",       "hud-ammo-he-icon",       "hud-detail-ammo-shells",  150, 1000, 15))
table.insert(Devices, Ammo("ammo_solid20",  "hud-ammo-solid20-icon",  "hud-detail-ammo-20mm",    150, 1000, 15))
table.insert(Devices, Ammo("ammo_shrapnel", "hud-ammo-shrapnel-icon", "hud-detail-ammo-20mm",    180, 1150, 15))
table.insert(Devices, Ammo("ammo_flak",     "hud-ammo-flak-icon",     "hud-detail-ammo-flak",    150, 1000, 15))
table.insert(Devices, Ammo("ammo_cluster",  "hud-ammo-cluster-icon",  "hud-detail-ammo-shells",  200, 1300, 15))
table.insert(Devices, Ammo("ammo_heat",     "hud-ammo-heat-icon",     "hud-detail-ammo-shells",  230, 1400, 15))
table.insert(Devices, Ammo("ammo_ap",       "hud-ammo-ap-icon",       "hud-detail-ammo-shells",  230, 1400, 15))
table.insert(Devices, Ammo("ammo_aarocket", "hud-ammo-aarocket-icon", "hud-detail-ammo-manpads", 170, 1100, 15))
table.insert(Devices, Ammo("ammo_emprocket","hud-ammo-emprocket-icon","hud-detail-ammo-manpads", 300, 1800, 15))
table.insert(Devices, Ammo("ammo_homingrocket","hud-ammo-homing-icon","hud-detail-ammo-manpads", 320, 2000, 15))
table.insert(Devices, Ammo("ammo_sam",      "hud-ammo-sam-icon",      "hud-detail-ammo-sam",     260, 1600, 15))
table.insert(Devices, Ammo("ammo_typhoon",   "hud-ammo-typhoon-icon",   "hud-detail-ammo-typhoon",  350, 2000, 15))
