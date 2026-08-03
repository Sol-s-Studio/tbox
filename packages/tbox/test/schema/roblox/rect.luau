--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/rect")

Helper.expectFail(Type:runtimeTypeCheck(Type.Rect(), 123), "Rect expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.Rect()), "Rect")
Helper.expectEqual(Type:format(Type.Rect()), "TRect")

const function mockVector2(x: number, y: number)
	return { X = x, Y = y }
end

const function mockRect(minX: number, minY: number, maxX: number, maxY: number)
	return {
		Min = mockVector2(minX, minY),
		Max = mockVector2(maxX, maxY),
		Width = maxX - minX,
		Height = maxY - minY,
	}
end

const schema = Type.Rect({ normalizedOnly = true, maxWidth = 10, minWidth = 1, maxHeight = 10, minHeight = 1 })

Helper.expectOk(Def.runtimeConstraintChecker(schema, mockRect(0, 0, 5, 5)))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockRect(5, 0, 0, 5)),
	"rect must be normalized, expected Min.X <= Max.X and Min.Y <= Max.Y"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockRect(0, 0, 20, 5)),
	"width too big. maximum allowed width is 10"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockRect(0, 0, 0.5, 5)),
	"width too small. minimum allowed width is 1"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockRect(0, 0, 5, 20)),
	"height too big. maximum allowed height is 10"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockRect(0, 0, 5, 0.5)),
	"height too small. minimum allowed height is 1"
)

const bounded = Type.Rect({ min = mockVector2(0, 0) :: any, max = mockVector2(10, 10) :: any })
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockRect(0, 0, 20, 5)),
	"max.x too big. maximum allowed max.x value is 10"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockRect(-1, 0, 5, 5)),
	"min.x too small. minimum allowed min.x value is 0"
)

return true
