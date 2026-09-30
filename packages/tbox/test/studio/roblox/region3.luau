--!strict

-- test/schema/roblox/region3.luau 의 mock 시나리오를 실제 Region3 로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

-- 원점 모서리에서 (x, y, z) 크기의 Region3
const function region(x: number, y: number, z: number): Region3
    return Region3.new(Vector3.zero, Vector3.new(x, y, z))
end

Helper.expectOk(Type:runtimeTypeCheck(Type.Region3(), region(1, 1, 1)))
Helper.expectFail(Type:runtimeTypeCheck(Type.Region3(), 123), "Region3 expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(Type.Region3(), Vector3.new(1, 1, 1)), "Region3 expected, but got Vector3")

-- 실제 Region3 는 Size 와 중심 CFrame 만 가진다 (Min/Max 없음)
Helper.expectEqual(region(2, 4, 6).Size, Vector3.new(2, 4, 6))
Helper.expectEqual(region(2, 4, 6).CFrame.Position, Vector3.new(1, 2, 3))

const schema = Type.Region3({
    minSize = Vector3.new(1, 1, 1),
    maxSize = Vector3.new(10, 10, 10),
    maxVolume = 500,
})

Helper.expectOk(Common.check(schema, region(5, 5, 5)))
Helper.expectFail(Common.check(schema, region(20, 5, 5)), "size.x too big. maximum allowed size.x value is 10")
Helper.expectFail(Common.check(schema, region(0.5, 5, 5)), "size.x too small. minimum allowed size.x value is 1")
Helper.expectFail(Common.check(schema, region(9, 9, 9)), "volume too big. maximum allowed volume is 500")

-- Rect 와 달리 Region3.new 는 뒤집힌 모서리(min > max)를 정규화하지 않고 음수 Size 로 저장한다
-- (Studio 에서 확인: Region3.new((5, 0, 0), (0, 5, 5)).Size == (-5, 5, 5)). minSize 를 주면 걸러지지만,
-- maxVolume 만 준 스키마는 음수 축이 홀수 개면 부피가 음수가 되어 어떤 크기라도 통과시킨다.
const inverted = Region3.new(Vector3.new(1000, 0, 0), Vector3.new(0, 1000, 1000))
Helper.expectEqual(inverted.Size, Vector3.new(-1000, 1000, 1000))
Helper.expectFail(
    Common.check(Type.Region3({ minSize = Vector3.new(1, 1, 1) }), inverted),
    "size.x too small. minimum allowed size.x value is 1"
)
Helper.pending("TRegion3 maxVolume should reject an inverted Region3 whose size is (-1000, 1000, 1000)", function()
    Helper.expectFail(
        Common.check(Type.Region3({ maxVolume = 500 }), inverted),
        "volume too big. maximum allowed volume is 500"
    )
end)

return true
