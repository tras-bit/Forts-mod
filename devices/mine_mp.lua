-- ============================================================
--  Military Pack: рескин ВАНИЛЬНОЙ шахты (M1 style, v4.6)
--  Текстура ровно 640x310, коллизия аккуратная
-- ============================================================

dofile("devices/mine.lua")

------------------- РУЧКИ (крутите здесь) -------------------
local MP_MODEL = 1.0    -- множитель поверх 640px спрайта (160 юнитов)
local MP_COLL  = 0.85   -- коллизия чуть меньше ванили (85%)
local MP_Y_UP  = -0.10  -- подъём модели из земли
------------------------------------------------------------

-- ванильная рамка коллизии (запоминаем ДО правок)
local V_W, V_H, V_OX, V_OY = 94.0, 43.5, 0.0, 0.0
if type(SelectionWidth)  == "number" then V_W = SelectionWidth end
if type(SelectionHeight) == "number" then V_H = SelectionHeight end
if type(SelectionOffset) == "table" then
    V_OX = SelectionOffset[1] or 0.0
    V_OY = SelectionOffset[2] or 0.0
end

Scale           = MP_MODEL
SelectionWidth  = V_W * MP_COLL / MP_MODEL
SelectionHeight = V_H * MP_COLL / MP_MODEL
SelectionOffset = { V_OX, (V_OY + MP_Y_UP * 80) / MP_MODEL }

if Root then
    if type(Root.PivotOffset) == "table" then
        Root.PivotOffset[2] = (Root.PivotOffset[2] or 0) + MP_Y_UP
    else
        Root.PivotOffset = { 0, MP_Y_UP }
    end
end

local tex   = path .. "/devices/media/mine.png"
local blank = path .. "/devices/media/blank.png"
local main  = Root and Root.Sprite or nil

if Sprites then
    for _, s in ipairs(Sprites) do
        if s.States then
            for _, st in pairs(s.States) do
                if st.Frames then
                    for _, f in ipairs(st.Frames) do
                        f.texture = (s.Name == main) and tex or blank
                    end
                end
            end
        end
    end
end
