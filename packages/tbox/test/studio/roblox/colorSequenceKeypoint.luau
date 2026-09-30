--!strict

-- test/schema/roblox/colorSequenceKeypoint.luau 의 mock 시나리오를 실제 값으로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

const white = Color3.new(1, 1, 1)

Helper.expectOk(Type:runtimeTypeCheck(Type.ColorSequenceKeypoint(), ColorSequenceKeypoint.new(0.5, white)))
Helper.expectFail(
    Type:runtimeTypeCheck(Type.ColorSequenceKeypoint(), 123),
    "ColorSequenceKeypoint expected, but got number"
)
Helper.expectFail(
    Type:runtimeTypeCheck(Type.ColorSequenceKeypoint(), NumberSequenceKeypoint.new(0.5, 1)),
    "ColorSequenceKeypoint expected, but got NumberSequenceKeypoint"
)

const schema = Type.ColorSequenceKeypoint({ minTime = 0.2, maxTime = 0.8 })

Helper.expectOk(Common.check(schema, ColorSequenceKeypoint.new(0.5, white)))
Helper.expectFail(
    Common.check(schema, ColorSequenceKeypoint.new(0.9, white)),
    "time too big. maximum allowed time is 0.8"
)
Helper.expectFail(
    Common.check(schema, ColorSequenceKeypoint.new(0.1, white)),
    "time too small. minimum allowed time is 0.2"
)

-- 시퀀스 밖에서 단독으로 만든 키포인트는 엔진이 Time 을 0~1 로 제한하지 않는다 (Studio 에서 확인: 1.5 가 그대로 저장됨).
-- 시퀀스에 넣을 때에야 거부되므로, 단독 키포인트를 받는 스키마라면 minTime/maxTime 이 실제로 의미가 있다.
Helper.expectEqual(ColorSequenceKeypoint.new(1.5, white).Time, 1.5)
Helper.expectFail(
    Common.check(schema, ColorSequenceKeypoint.new(1.5, white)),
    "time too big. maximum allowed time is 0.8"
)

-- Time 은 32비트 float 로 저장된다. 그래서 ColorSequenceKeypoint.new(0.8, ...) 의 Time 은 0.800000011920929 로
-- 64비트 0.8 보다 크다. src 는 경계도 float32 로 맞춰 비교하므로 경계값 그 자체는 허용되어야 한다.
Helper.expectEqual(ColorSequenceKeypoint.new(0.8, white).Time > 0.8, true)
Helper.expectOk(Common.check(schema, ColorSequenceKeypoint.new(0.8, white)))

return true
