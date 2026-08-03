--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/color3")

Helper.expectFail(Type:runtimeTypeCheck(Type.Color3(), 123), "Color3 expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.Color3()), "Color3")
Helper.expectEqual(Type:format(Type.Color3()), "TColor3")

const function mockColor3(r: number, g: number, b: number)
	return { R = r, G = g, B = b }
end

const schema = Type.Color3({ clampedOnly = true, notNan = true })

Helper.expectOk(Def.runtimeConstraintChecker(schema, mockColor3(0.5, 0.5, 0.5)))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockColor3(1.5, 0, 0)),
	"color components must be within 0 and 1"
)
Helper.expectFail(Def.runtimeConstraintChecker(schema, mockColor3(0 / 0, 0, 0)), "nan is not allowed")

const bounded = Type.Color3({ min = mockColor3(0, 0, 0) :: any, max = mockColor3(0.5, 0.5, 0.5) :: any })
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockColor3(0.9, 0, 0)),
	"r value too big. maximum allowed r value is 0.5"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockColor3(-0.1, 0, 0)),
	"r value too small. minimum allowed r value is 0"
)

return true
