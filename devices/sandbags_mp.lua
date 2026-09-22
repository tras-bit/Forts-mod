-- ============================================================
--  Military Pack: МЕШОК С ПЕСКОМ (стиль мода, v4.7)
--  Перекрывает ванильный sandbags: новая мировая текстура,
--  новая HUD-иконка, новая карточка деталей.
--
--  Подключается ПОСЛЕ ванильного devices/sandbags.lua, поэтому
--  просто переопределяем спрайт через ReplaceSprite и меняем
--  корневой спрайт на зарегистрированный нами.
-- ============================================================

dofile("devices/sandbags.lua")

local MP_TEX = path .. "/devices/media/mpsandbags.png"

-- Регистрируем спрайт мешка в стиле мода (защита от дубликата:
-- файл может подключаться повторно при перезагрузке мода).
local function MP_HasSprite(name)
    if type(Sprites) ~= "table" then return false end
    for _, sp in ipairs(Sprites) do
        if type(sp) == "table" and sp.Name == name then return true end
    end
    return false
end

if not MP_HasSprite("mp-sandbags-base") then
    table.insert(Sprites,
    {
        Name = "mp-sandbags-base",
        States =
        {
            Normal = { Frames = { { texture = MP_TEX }, mipmap = true, }, },
        },
    })
end

-- Переключаем корневой спрайт на наш
if Root then
    Root.Sprite = "mp-sandbags-base"
end

-- На всякий случай гасим ванильный спрайт, чтобы движок не тянул
-- старую текстуру даже если Root.Sprite не применился.
if Sprites then
    for _, sp in ipairs(Sprites) do
        if type(sp) == "table" and sp.Name == "sandbags-base" then
            sp.States = { Normal = { Frames = { { texture = MP_TEX }, mipmap = true, }, }, }
        end
    end
end
