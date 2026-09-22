-- ============================================================
--  Military Pack: правило DefaultMovePeriod
--  Длительность перемещения устройств пассивкой Фантома.
--  Ставим недостижимое значение — перемещение перестаёт работать.
-- ============================================================
local MP_NO_MOVE_PERIOD = 999999

if type(Rules) ~= "table" then Rules = {} end
Rules.DefaultMovePeriod = MP_NO_MOVE_PERIOD
DefaultMovePeriod       = MP_NO_MOVE_PERIOD
