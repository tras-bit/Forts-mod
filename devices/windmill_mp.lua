-- ============================================================
--  Military Pack: ВЕТРЯК, ПЕРВЫЙ УРОВЕНЬ (v3.8)
--
--  Схема — ванильная, без покадровки:
--    Root    — мачта с гондолой, стоит неподвижно   base.png
--    Nacelle — пустая точка (спрайт ТОГО ЖЕ размера,
--              что и base) поднимает origin к ступице nac.png
--    Head    — ротор (3 лопасти), его крутит САМ
--              ДВИЖОК (UserData = 50)               head.png
--
--  Почему так: движок множит доли PivotOffset на ОДНУ сторону
--  спрайта — и оказалось, что на ШИРИНУ, а не на высоту. Пока
--  кадр был 480x649, подъём выходил 0.5152*480 = 247 px вместо
--  0.5152*649 = 334 px: ось вставала на лопасть, ротор уезжал.
--  Поэтому ВСЕ четыре спрайта — КВАДРАТ 649x649 одного размера:
--  ширина/высота, свой/родительский/дочерний — всё даёт 334 px.
--  Ротор лежит в том же квадрате, ступица ровно в центре, поэтому
--  Pivot = {0,0} и знак с долями роли не играют.
--
--  Размер v3.8.2 (в 2 раза крупнее v3.8.1): квадратный холст 925x925 px,
--  видимая модель 236 x 285 юнита (v3.7 было 59 x 71.6, v3.8.1 118 x 143).
--  MP_SCALE = 1.4 домножает модель поверх спрайта; рамка Selection*
--  поделена на него, поэтому колизия та же: 40 x 63, {0, -63.5}.
--  Подножие мачты стоит точно в якоре устройства.
--  Рамка коллизии НЕ ТРОНУТА: 40 x 63, смещение {0, -63.5}.
--  Ручка размера: MP_SCALE в начале файла (1.0 = как сейчас).
-- ============================================================

local MP_SCALE = 1.4     -- v3.8.2: модель ещё в 1.4 раза крупнее спрайта

ConstructEffect = "effects/device_construct.lua"
CompleteEffect = "effects/device_complete.lua"
DestroyUnderwaterEffect = "mods/dlc2/effects/device_explode_submerged.lua"

Scale = MP_SCALE
-- рамка делится на масштаб: движок множит её на Scale, а нам нужна
-- СТАРАЯ колизия 40 x 63 со смещением {0, -63.5} при любом размере модели
SelectionWidth = 40.0 / MP_SCALE
SelectionHeight = 63.0 / MP_SCALE
SelectionOffset = { 0.0, -63.5 / MP_SCALE }

Mass = 70.0
HitPoints = 105.0
EnergyProductionRate = 45.0
MetalProductionRate = 0.0
EnergyStorageCapacity = 0.0
MetalStorageCapacity = 0.0

MinWindEfficiency = 0.25
MinWindNoCrossFlow = 0.3
MinWindCrossFlow = 0.35
MaxWindHeight = 900
MinTestDistance = 25
MaxTestDistance = 600
MinWindAngle = -10
MaxWindAngle = 10
MaxRotationalSpeed = 7          -- скорость вращения ротора (ванильная)

dofile("effects/device_smoke.lua")
SmokeEmitter = StandardDeviceSmokeEmitter

Sprites =
{
	{
		Name = "mp-wind-base",
		States =
		{
			Normal = { Frames = { { texture = path .. "/devices/media/windmill/base.png" }, mipmap = true, }, },
		},
	},
	{
		Name = "mp-wind-nac",
		States =
		{
			Normal = { Frames = { { texture = path .. "/devices/media/windmill/nac2.png" }, }, },
			Idle = Normal,
		},
	},
	{
		Name = "mp-wind-head",
		States =
		{
			Normal = { Frames = { { texture = path .. "/devices/media/windmill/head.png" }, mipmap = true, }, },
		},
	},
}

NodeEffects =
{
	{
		NodeName = "Head",
		EffectPath = "effects/windturbine_ambient.lua",
	},
}

Root =
{
	Name = "Turbine",
	Angle = 0,
	Pivot = { 0, -0.385 },                 -- якорь у подножия мачты (ванильное значение)
	PivotOffset = { 0, 0 },
	Sprite = "mp-wind-base",
	UserData = 0,

	ChildrenInFront =
	{
		{
			-- v3.8: пустая точка, ТОТ ЖЕ размер спрайта, что и base.png.
			-- Она поднимает origin от подножия мачты к ступице ротора.
			Name = "Nacelle",
			Angle = 0,
			Pivot = { 0, 0 },
			PivotOffset = { 0.0000, -0.1672 },   -- точная ступица на вершине башни (+475.8 px над полом)
			Sprite = "mp-wind-nac",
			UserData = 0,

			ChildrenInFront =
			{
				{
					Name = "Head",             -- ИМЯ НЕ МЕНЯТЬ: по нему движок крутит ротор
					Angle = 0,
					Pivot = { 0.0000, 0.0000 },   -- ротор — плотный квадрат, ступица ровно в центре
					PivotOffset = { 0, 0 },     -- origin УЖЕ в ступице (его поднял Nacelle)
					Sprite = "mp-wind-head",
					UserData = 50,
				},
			},
		},
		{
			Name = "Icon",
			Pivot = { 0, 0.5 },
		},
	},
}
