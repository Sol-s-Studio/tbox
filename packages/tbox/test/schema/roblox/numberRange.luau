--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/numberRange")

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

return true
