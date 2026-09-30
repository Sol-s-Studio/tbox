--!strict

-- test/schema/roblox/udim2.luau 의 mock 시나리오를 실제 UDim2 로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

Helper.expectOk(Type:runtimeTypeCheck(Type.UDim2(), UDim2.new()))
Helper.expectFail(Type:runtimeTypeCheck(Type.UDim2(), 123), "UDim2 expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(Type.UDim2(), UDim.new()), "UDim2 expected, but got UDim")
Helper.expectFail(Type:runtimeTypeCheck(Type.UDim2(), Vector2.new()), "UDim2 expected, but got Vector2")

const schema = Type.UDim2({ maxXScale = 1, minYOffset = 0, maxYOffset = 100 })

Helper.expectOk(Common.check(schema, UDim2.new(0.5, 0, 0, 50)))
-- UDim 두 개를 받는 생성자도 같은 값이 된다
Helper.expectOk(Common.check(schema, UDim2.new(UDim.new(0.5, 0), UDim.new(0, 50))))
Helper.expectFail(Common.check(schema, UDim2.new(1.5, 0, 0, 0)), "x scale too big. maximum allowed x scale is 1")
Helper.expectFail(Common.check(schema, UDim2.new(0, 0, 0, 200)), "y offset too big. maximum allowed y offset is 100")
Helper.expectFail(Common.check(schema, UDim2.new(0, 0, 0, -1)), "y offset too small. minimum allowed y offset is 0")

const scaleOnly = Type.UDim2({ scaleOnly = true })
Helper.expectOk(Common.check(scaleOnly, UDim2.fromScale(0.5, 0.5)))
Helper.expectFail(
    Common.check(scaleOnly, UDim2.new(0.5, 10, 0, 0)),
    "x offset must be zero when scaleOnly is set, but got 10"
)
Helper.expectFail(
    Common.check(scaleOnly, UDim2.new(0.5, 0, 0.5, 10)),
    "y offset must be zero when scaleOnly is set, but got 10"
)

const offsetOnly = Type.UDim2({ offsetOnly = true })
Helper.expectOk(Common.check(offsetOnly, UDim2.fromOffset(10, 20)))
Helper.expectFail(
    Common.check(offsetOnly, UDim2.fromScale(0.5, 0)),
    "x scale must be zero when offsetOnly is set, but got 0.5"
)

-- UDim 과 마찬가지로 Offset 은 32비트 정수라 integerOffsetOnly 는 실제 값에 대해 항상 통과한다
Helper.expectEqual(UDim2.new(0, 1.5, 0, 0).X.Offset, 1)
Helper.expectOk(Common.check(Type.UDim2({ integerOffsetOnly = true }), UDim2.new(0, 1.5, 0, 2.5)))

return true
