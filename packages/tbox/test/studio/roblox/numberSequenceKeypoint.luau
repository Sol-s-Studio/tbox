--!strict

-- test/schema/roblox/numberSequenceKeypoint.luau 의 mock 시나리오를 실제 값으로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

Helper.expectOk(Type:runtimeTypeCheck(Type.NumberSequenceKeypoint(), NumberSequenceKeypoint.new(0.5, 1)))
Helper.expectFail(
    Type:runtimeTypeCheck(Type.NumberSequenceKeypoint(), 123),
    "NumberSequenceKeypoint expected, but got number"
)
Helper.expectFail(
    Type:runtimeTypeCheck(Type.NumberSequenceKeypoint(), ColorSequenceKeypoint.new(0.5, Color3.new())),
    "NumberSequenceKeypoint expected, but got ColorSequenceKeypoint"
)

const schema = Type.NumberSequenceKeypoint({
    minTime = 0.2,
    maxTime = 0.8,
    minValue = 0,
    maxValue = 1,
    maxEnvelope = 0.1,
})

Helper.expectOk(Common.check(schema, NumberSequenceKeypoint.new(0.5, 0.5, 0)))
Helper.expectFail(
    Common.check(schema, NumberSequenceKeypoint.new(0.9, 0.5, 0)),
    "NumberSequenceKeypoint.Time too big. maximum allowed value is 0.8"
)
Helper.expectFail(
    Common.check(schema, NumberSequenceKeypoint.new(0.1, 0.5, 0)),
    "NumberSequenceKeypoint.Time too small. minimum allowed value is 0.2"
)
Helper.expectFail(
    Common.check(schema, NumberSequenceKeypoint.new(0.5, 2, 0)),
    "NumberSequenceKeypoint.Value too big. maximum allowed value is 1"
)
Helper.expectFail(
    Common.check(schema, NumberSequenceKeypoint.new(0.5, -1, 0)),
    "NumberSequenceKeypoint.Value too small. minimum allowed value is 0"
)
Helper.expectFail(
    Common.check(schema, NumberSequenceKeypoint.new(0.5, 0.5, 0.5)),
    "NumberSequenceKeypoint.Envelope too big. maximum allowed value is 0.1"
)

-- 봉투(envelope) 생략 시 0 이다
Helper.expectEqual(NumberSequenceKeypoint.new(0.5, 0.5).Envelope, 0)

const zeroEnvelope = Type.NumberSequenceKeypoint({ envelopeMustBeZero = true })
Helper.expectOk(Common.check(zeroEnvelope, NumberSequenceKeypoint.new(0, 0, 0)))
-- mock 과 달리 실제 Envelope 는 32비트 float 로 저장되므로 0.2 가 0.20000000298023224 로 보고된다
-- (Studio 에서 확인). 값을 그대로 보여주는 에러 메시지라 문구가 mock 버전과 다르다.
Helper.expectFail(
    Common.check(zeroEnvelope, NumberSequenceKeypoint.new(0, 0, 0.2)),
    "NumberSequenceKeypoint.Envelope must be zero, but got 0.20000000298023224"
)

-- 단독 키포인트는 엔진이 Time 범위도, 음수 봉투도 막지 않는다 (시퀀스에 넣을 때만 거부된다 — numberSequence.luau 참고)
Helper.expectEqual(NumberSequenceKeypoint.new(1.5, 0).Time, 1.5)
Helper.expectEqual(NumberSequenceKeypoint.new(0, 0, -0.5).Envelope, -0.5)
Helper.expectFail(
    Common.check(schema, NumberSequenceKeypoint.new(1.5, 0.5, 0)),
    "NumberSequenceKeypoint.Time too big. maximum allowed value is 0.8"
)

return true
