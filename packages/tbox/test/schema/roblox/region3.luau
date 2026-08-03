--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/region3")

Helper.expectFail(Type:runtimeTypeCheck(Type.Region3(), 123), "Region3 expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.Region3()), "Region3")
Helper.expectEqual(Type:format(Type.Region3()), "TRegion3")

const function mockRegion3(x: number, y: number, z: number)
	return { Size = { X = x, Y = y, Z = z } }
end

const schema = Type.Region3({
	minSize = mockRegion3(1, 1, 1).Size :: any,
	maxSize = mockRegion3(10, 10, 10).Size :: any,
	maxVolume = 500,
})

Helper.expectOk(Def.runtimeConstraintChecker(schema, mockRegion3(5, 5, 5)))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockRegion3(20, 5, 5)),
	"size.x too big. maximum allowed size.x value is 10"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockRegion3(0.5, 5, 5)),
	"size.x too small. minimum allowed size.x value is 1"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockRegion3(9, 9, 9)),
	"volume too big. maximum allowed volume is 500"
)

return true
