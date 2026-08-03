--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/udim2")

Helper.expectFail(Type:runtimeTypeCheck(Type.UDim2(), 123), "UDim2 expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.UDim2()), "UDim2")
Helper.expectEqual(Type:format(Type.UDim2()), "TUDim2")

const function mockUDim(scale: number, offset: number)
	return { Scale = scale, Offset = offset }
end

const function mockUDim2(xScale: number, xOffset: number, yScale: number, yOffset: number)
	return { X = mockUDim(xScale, xOffset), Y = mockUDim(yScale, yOffset) }
end

const schema = Type.UDim2({ maxXScale = 1, minYOffset = 0, maxYOffset = 100 })

Helper.expectOk(Def.runtimeConstraintChecker(schema, mockUDim2(0.5, 0, 0, 50)))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockUDim2(1.5, 0, 0, 0)),
	"x scale too big. maximum allowed x scale is 1"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockUDim2(0, 0, 0, 200)),
	"y offset too big. maximum allowed y offset is 100"
)

const scaleOnly = Type.UDim2({ scaleOnly = true })
Helper.expectFail(
	Def.runtimeConstraintChecker(scaleOnly, mockUDim2(0.5, 10, 0, 0)),
	"x offset must be zero when scaleOnly is set, but got 10"
)

return true
