--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/vector3")

Helper.expectFail(Type:runtimeTypeCheck(Type.Vector3(), 123), "Vector3 expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.Vector3()), "Vector3")
Helper.expectEqual(Type:format(Type.Vector3()), "TVector3")

const function mockVector3(x: number, y: number, z: number)
	return { X = x, Y = y, Z = z, Magnitude = math.sqrt(x * x + y * y + z * z) }
end

const schema = Type.Vector3({ maxMagnitude = 10, minMagnitude = 1 })

Helper.expectOk(Def.runtimeConstraintChecker(schema, mockVector3(1, 2, 2)))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockVector3(100, 0, 0)),
	"Vector3 too long. maximum allowed magnitude is 10"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockVector3(0.1, 0, 0)),
	"Vector3 too short. minimum allowed magnitude is 1"
)

const strict = Type.Vector3({ integerOnly = true, notNan = true })
Helper.expectOk(Def.runtimeConstraintChecker(strict, mockVector3(1, 2, 2)))
Helper.expectFail(
	Def.runtimeConstraintChecker(strict, mockVector3(1.5, 2, 2)),
	"x component must be an integer, but got 1.5"
)
Helper.expectFail(Def.runtimeConstraintChecker(strict, mockVector3(0 / 0, 2, 2)), "x component must not be nan")

const bounded = Type.Vector3({ min = mockVector3(0, 0, 0) :: any, max = mockVector3(10, 10, 10) :: any })
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockVector3(11, 0, 0)),
	"x value too big. maximum allowed x value is 10"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockVector3(-1, 0, 0)),
	"x value too small. minimum allowed x value is 0"
)

return true
