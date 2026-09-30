--!strict

-- test/schema/roblox/color3.luau 의 mock 시나리오를 실제 Color3 값으로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

Helper.expectOk(Type:runtimeTypeCheck(Type.Color3(), Color3.new(0.5, 0.5, 0.5)))
Helper.expectOk(Type:runtimeTypeCheck(Type.Color3(), Color3.fromHex("#FF8800")))
Helper.expectFail(Type:runtimeTypeCheck(Type.Color3(), 123), "Color3 expected, but got number")
Helper.expectFail(
    Type:runtimeTypeCheck(Type.Color3(), BrickColor.new("Bright red")),
    "Color3 expected, but got BrickColor"
)

const schema = Type.Color3({ clampedOnly = true, notNan = true })

Helper.expectOk(Common.check(schema, Color3.new(0.5, 0.5, 0.5)))
Helper.expectOk(Common.check(schema, Color3.fromRGB(255, 128, 0)))
Helper.expectOk(Common.check(schema, Color3.fromHSV(0.9, 1, 1)))
-- Color3.new 는 0~1 범위 밖 값과 nan 을 그대로 저장한다 (Studio 에서 확인: Color3.new(1.5, 0, 0).R == 1.5)
Helper.expectFail(Common.check(schema, Color3.new(1.5, 0, 0)), "color components must be within 0 and 1")
Helper.expectFail(Common.check(schema, Color3.new(0, 0, -0.5)), "color components must be within 0 and 1")
Helper.expectFail(Common.check(schema, Color3.new(0 / 0, 0, 0)), "nan is not allowed")

-- min/max 도 실제 Color3 로 준다. 성분이 32비트 float 로 저장되는 점은 옵션 쪽도 똑같이 적용되므로 비교가 어긋나지 않는다
const bounded = Type.Color3({ min = Color3.new(0, 0, 0), max = Color3.new(0.5, 0.5, 0.5) })
Helper.expectOk(Common.check(bounded, Color3.new(0.5, 0.5, 0.5)))
Helper.expectFail(Common.check(bounded, Color3.new(0.9, 0, 0)), "r value too big. maximum allowed r value is 0.5")
Helper.expectFail(Common.check(bounded, Color3.new(-0.1, 0, 0)), "r value too small. minimum allowed r value is 0")
Helper.expectFail(Common.check(bounded, Color3.new(0, 0, 1)), "b value too big. maximum allowed b value is 0.5")

return true
