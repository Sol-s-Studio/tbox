--!strict

-- test/schema/roblox/udim.luau 의 mock 시나리오를 실제 UDim 으로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

Helper.expectOk(Type:runtimeTypeCheck(Type.UDim(), UDim.new(0.5, 10)))
Helper.expectFail(Type:runtimeTypeCheck(Type.UDim(), 123), "UDim expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(Type.UDim(), UDim2.new()), "UDim expected, but got UDim2")

const scaleOnly = Type.UDim({ scaleOnly = true })
Helper.expectOk(Common.check(scaleOnly, UDim.new(0.5, 0)))
Helper.expectFail(Common.check(scaleOnly, UDim.new(0.5, 10)), "offset must be zero when scaleOnly is set, but got 10")

const offsetOnly = Type.UDim({ offsetOnly = true })
Helper.expectOk(Common.check(offsetOnly, UDim.new(0, 10)))
Helper.expectFail(Common.check(offsetOnly, UDim.new(0.5, 10)), "scale must be zero when offsetOnly is set, but got 0.5")

-- Offset 은 32비트 정수로 저장된다 (Studio 에서 확인: UDim.new(0, 1.5).Offset == 1, UDim.new(0, 3e9).Offset 은
-- 오버플로해 -2147483648). 그래서 mock 의 "Offset 1.5" 는 실제로 만들 수 없고, integerOffsetOnly 는
-- 실제 UDim 에 대해 항상 통과한다 (src 에서 지워도 되는 옵션인지는 결정 필요 — 보고 참고).
Helper.expectEqual(UDim.new(0, 1.5).Offset, 1)
Helper.expectOk(Common.check(Type.UDim({ integerOffsetOnly = true }), UDim.new(0, 1.5)))

const bounded = Type.UDim({ minScale = 0, maxScale = 1, minOffset = 0, maxOffset = 100 })
Helper.expectOk(Common.check(bounded, UDim.new(1, 100)))
Helper.expectFail(Common.check(bounded, UDim.new(1.5, 0)), "scale too big. maximum allowed scale is 1")
Helper.expectFail(Common.check(bounded, UDim.new(-0.5, 0)), "scale too small. minimum allowed scale is 0")
Helper.expectFail(Common.check(bounded, UDim.new(0, 200)), "offset too big. maximum allowed offset is 100")
Helper.expectFail(Common.check(bounded, UDim.new(0, -1)), "offset too small. minimum allowed offset is 0")

return true
