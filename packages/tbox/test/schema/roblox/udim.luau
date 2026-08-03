--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/udim")

Helper.expectFail(Type:runtimeTypeCheck(Type.UDim(), 123), "UDim expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.UDim()), "UDim")
Helper.expectEqual(Type:format(Type.UDim()), "TUDim")

const function mockUDim(scale: number, offset: number)
	return { Scale = scale, Offset = offset }
end

const scaleOnly = Type.UDim({ scaleOnly = true })
Helper.expectOk(Def.runtimeConstraintChecker(scaleOnly, mockUDim(0.5, 0)))
Helper.expectFail(
	Def.runtimeConstraintChecker(scaleOnly, mockUDim(0.5, 10)),
	"offset must be zero when scaleOnly is set, but got 10"
)

const offsetOnly = Type.UDim({ offsetOnly = true })
Helper.expectOk(Def.runtimeConstraintChecker(offsetOnly, mockUDim(0, 10)))
Helper.expectFail(
	Def.runtimeConstraintChecker(offsetOnly, mockUDim(0.5, 10)),
	"scale must be zero when offsetOnly is set, but got 0.5"
)

const integerOffsetOnly = Type.UDim({ integerOffsetOnly = true })
Helper.expectFail(
	Def.runtimeConstraintChecker(integerOffsetOnly, mockUDim(0, 1.5)),
	"offset must be an integer, but got 1.5"
)

const bounded = Type.UDim({ minScale = 0, maxScale = 1, minOffset = 0, maxOffset = 100 })
Helper.expectFail(Def.runtimeConstraintChecker(bounded, mockUDim(1.5, 0)), "scale too big. maximum allowed scale is 1")
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockUDim(-0.5, 0)),
	"scale too small. minimum allowed scale is 0"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockUDim(0, 200)),
	"offset too big. maximum allowed offset is 100"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockUDim(0, -1)),
	"offset too small. minimum allowed offset is 0"
)

return true
