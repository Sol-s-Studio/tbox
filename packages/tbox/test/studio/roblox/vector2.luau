--!strict

-- test/schema/roblox/vector2.luau 의 mock 시나리오를 실제 Vector2 값으로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

-- 타입 검사: 실제 typeof 분기
Helper.expectOk(Type:runtimeTypeCheck(Type.Vector2(), Vector2.new(3, 4)))
Helper.expectOk(Type:runtimeTypeCheck(Type.Vector2(), Vector2.zero))
Helper.expectFail(Type:runtimeTypeCheck(Type.Vector2(), 123), "Vector2 expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(Type.Vector2(), Vector3.new(3, 4, 0)), "Vector2 expected, but got Vector3")
Helper.expectFail(Type:runtimeTypeCheck(Type.Vector2(), UDim2.new()), "Vector2 expected, but got UDim2")

const schema = Type.Vector2({ maxMagnitude = 10, minMagnitude = 1 })

Helper.expectOk(Common.check(schema, Vector2.new(3, 4)))
Helper.expectFail(Common.check(schema, Vector2.new(100, 0)), "Vector2 too long. maximum allowed magnitude is 10")
Helper.expectFail(Common.check(schema, Vector2.new(0.1, 0)), "Vector2 too short. minimum allowed magnitude is 1")

-- 엔진은 nan 성분도 그대로 저장한다 (Studio 에서 확인) — mock 과 같은 시나리오가 실제로도 성립한다
const strict = Type.Vector2({ integerOnly = true, notNan = true })
Helper.expectOk(Common.check(strict, Vector2.new(1, 4)))
Helper.expectFail(Common.check(strict, Vector2.new(1.5, 4)), "x component must be an integer, but got 1.5")
Helper.expectFail(Common.check(strict, Vector2.new(4, 2.5)), "y component must be an integer, but got 2.5")
Helper.expectFail(Common.check(strict, Vector2.new(0 / 0, 4)), "x component must not be nan")

-- min/max 옵션에도 mock 대신 실제 Vector2 를 넘긴다
const bounded = Type.Vector2({ min = Vector2.new(0, 0), max = Vector2.new(10, 10) })
Helper.expectOk(Common.check(bounded, Vector2.new(10, 0)))
Helper.expectFail(Common.check(bounded, Vector2.new(11, 0)), "x value too big. maximum allowed x value is 10")
Helper.expectFail(Common.check(bounded, Vector2.new(-1, 0)), "x value too small. minimum allowed x value is 0")
Helper.expectFail(Common.check(bounded, Vector2.new(5, 11)), "y value too big. maximum allowed y value is 10")

return true
