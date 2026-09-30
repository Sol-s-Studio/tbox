--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/numberRange")
const Util = require("../../../src/util")

Helper.expectFail(Type:runtimeTypeCheck(Type.NumberRange(), 123), "NumberRange expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.NumberRange()), "NumberRange")
Helper.expectEqual(Type:format(Type.NumberRange()), "TNumberRange")

const schema = Type.NumberRange({ min = 0, max = 10, minSpan = 1, maxSpan = 5, disallowEmpty = true })

Helper.expectOk(Def.runtimeConstraintChecker(schema, { Min = 1, Max = 4 }))
Helper.expectFail(
    Def.runtimeConstraintChecker(schema, { Min = 5, Max = 5 }),
    "NumberRange must not be empty. Min and Max must not be equal"
)
Helper.expectFail(
    Def.runtimeConstraintChecker(schema, { Min = 1, Max = 11 }),
    "NumberRange.Max too big. maximum allowed value is 10"
)
Helper.expectFail(
    Def.runtimeConstraintChecker(schema, { Min = -1, Max = 1 }),
    "NumberRange.Min too small. minimum allowed value is 0"
)
Helper.expectFail(
    Def.runtimeConstraintChecker(schema, { Min = 1, Max = 7 }),
    "NumberRange too wide. maximum allowed span (Max - Min) is 5"
)
Helper.expectFail(
    Def.runtimeConstraintChecker(schema, { Min = 1, Max = 1.5 }),
    "NumberRange too narrow. minimum allowed span (Max - Min) is 1"
)

-- 실제 Min/Max 는 float32 로 저장된다 (NumberRange.new(0, 0.1).Max == 0.10000000149011612). 경계를 float32 로
-- 맞춰 비교하므로 경계값으로 만든 범위는 통과하고, float32 로 한 칸 위인 값은 거부된다
const tight = Type.NumberRange({ min = 0.1, max = 0.1 })
Helper.expectOk(Def.runtimeConstraintChecker(tight, { Min = Util.toFloat32(0.1), Max = Util.toFloat32(0.1) }))
Helper.expectFail(
    Def.runtimeConstraintChecker(tight, { Min = Util.toFloat32(0.1), Max = Util.toFloat32(0.1) + 1e-8 }),
    "NumberRange.Max too big. maximum allowed value is 0.1"
)

return true
