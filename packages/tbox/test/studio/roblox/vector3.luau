--!strict

-- test/schema/roblox/vector3.luau 의 mock 시나리오를 실제 Vector3 값으로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

Helper.expectOk(Type:runtimeTypeCheck(Type.Vector3(), Vector3.new(1, 2, 2)))
Helper.expectOk(Type:runtimeTypeCheck(Type.Vector3(), Vector3.FromNormalId(Enum.NormalId.Top)))
Helper.expectFail(Type:runtimeTypeCheck(Type.Vector3(), 123), "Vector3 expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(Type.Vector3(), Vector2.new(1, 2)), "Vector3 expected, but got Vector2")
Helper.expectFail(Type:runtimeTypeCheck(Type.Vector3(), CFrame.new(1, 2, 3)), "Vector3 expected, but got CFrame")

-- Roblox 에서는 네이티브 vector 와 Vector3 가 같은 값이다: typeof(vector.create(...)) == "Vector3" (Studio 에서 확인).
-- 그래서 TVector3 는 vector.create 로 만든 값도 받는다. (반대로 TVector 가 Roblox 에서 vector 를 거부하는 문제는
-- test/schema/vector.luau 의 pending 참고)
Helper.expectEqual(typeof(vector.create(1, 2, 2)), "Vector3")
Helper.expectOk(Common.check(Type.Vector3(), vector.create(1, 2, 2)))

const schema = Type.Vector3({ maxMagnitude = 10, minMagnitude = 1 })

Helper.expectOk(Common.check(schema, Vector3.new(1, 2, 2)))
Helper.expectFail(Common.check(schema, Vector3.new(100, 0, 0)), "Vector3 too long. maximum allowed magnitude is 10")
Helper.expectFail(Common.check(schema, Vector3.new(0.1, 0, 0)), "Vector3 too short. minimum allowed magnitude is 1")

const strict = Type.Vector3({ integerOnly = true, notNan = true })
Helper.expectOk(Common.check(strict, Vector3.new(1, 2, 2)))
Helper.expectFail(Common.check(strict, Vector3.new(1.5, 2, 2)), "x component must be an integer, but got 1.5")
Helper.expectFail(Common.check(strict, Vector3.new(1, 2, 0.5)), "z component must be an integer, but got 0.5")
Helper.expectFail(Common.check(strict, Vector3.new(0 / 0, 2, 2)), "x component must not be nan")

const bounded = Type.Vector3({ min = Vector3.new(0, 0, 0), max = Vector3.new(10, 10, 10) })
Helper.expectOk(Common.check(bounded, Vector3.new(10, 10, 10)))
Helper.expectFail(Common.check(bounded, Vector3.new(11, 0, 0)), "x value too big. maximum allowed x value is 10")
Helper.expectFail(Common.check(bounded, Vector3.new(-1, 0, 0)), "x value too small. minimum allowed x value is 0")
Helper.expectFail(Common.check(bounded, Vector3.new(0, 0, -1)), "z value too small. minimum allowed z value is 0")

return true
