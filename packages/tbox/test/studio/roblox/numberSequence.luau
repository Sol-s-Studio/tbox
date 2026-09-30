--!strict

-- test/schema/roblox/numberSequence.luau 의 mock 시나리오를 실제 NumberSequence 로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

-- { time, value, envelope? } 목록으로 실제 NumberSequence 를 만든다
const function sequence(points: { { number } }): NumberSequence
    const result = {}
    for _, point in points do
        table.insert(result, NumberSequenceKeypoint.new(point[1], point[2], point[3] or 0))
    end
    return NumberSequence.new(result)
end

Helper.expectOk(Type:runtimeTypeCheck(Type.NumberSequence(), NumberSequence.new(1)))
Helper.expectFail(Type:runtimeTypeCheck(Type.NumberSequence(), 123), "NumberSequence expected, but got number")
Helper.expectFail(
    Type:runtimeTypeCheck(Type.NumberSequence(), ColorSequence.new(Color3.new())),
    "NumberSequence expected, but got ColorSequence"
)
Helper.expectFail(
    Type:runtimeTypeCheck(Type.NumberSequence(), NumberRange.new(1)),
    "NumberSequence expected, but got NumberRange"
)

const schema =
    Type.NumberSequence({ minKeypoints = 2, maxKeypoints = 3, minValue = 0, maxValue = 1, maxEnvelope = 0.2 })

Helper.expectOk(Common.check(schema, sequence({ { 0, 0 }, { 1, 1 } })))
Helper.expectOk(Common.check(schema, NumberSequence.new(0, 1)))
Helper.expectFail(
    Common.check(schema, sequence({ { 0, 0 }, { 0.25, 0 }, { 0.5, 0 }, { 1, 0 } })),
    "NumberSequence has too many keypoints. maximum allowed count is 3"
)
Helper.expectFail(
    Common.check(schema, sequence({ { 0, 0 }, { 1, 2 } })),
    "NumberSequence keypoint 2 Value too big. maximum allowed value is 1"
)
Helper.expectFail(
    Common.check(schema, sequence({ { 0, -1 }, { 1, 1 } })),
    "NumberSequence keypoint 1 Value too small. minimum allowed value is 0"
)
-- 첫 키포인트의 봉투도 시퀀스 안에서 그대로 보존된다 (Studio 에서 확인)
Helper.expectFail(
    Common.check(schema, sequence({ { 0, 0, 0.5 }, { 1, 1 } })),
    "NumberSequence keypoint 1 Envelope too big. maximum allowed value is 0.2"
)

-- mock 의 "키포인트 1개" 시나리오는 엔진이 생성 시점에 거부한다. minKeypoints 를 올려 같은 분기를 태운다.
Helper.expectError(function()
    sequence({ { 0, 0 } })
end, "NumberSequence: requires at least 2 keypoints")
Helper.expectFail(
    Common.check(Type.NumberSequence({ minKeypoints = 3 }), NumberSequence.new(0, 1)),
    "NumberSequence has too few keypoints. minimum allowed count is 3"
)

-- 시퀀스 안에서는 음수 봉투를 엔진이 거부한다 (단독 NumberSequenceKeypoint 는 허용)
Helper.expectError(function()
    sequence({ { 0, 0, -0.5 }, { 1, 1 } })
end, "NumberSequence: envelope must be non-negative")

-- 최대 20개 제한도 ColorSequence 와 같다
const twentyOne = {}
for index = 0, 20 do
    table.insert(twentyOne, { index / 20, 0 })
end
Helper.expectError(function()
    sequence(twentyOne)
end, "NumberSequence.new(): table is too long.")

-- strictKeypointOrder 의 실패 분기(최소 2개 / 첫 Time 0 / 마지막 Time 1 / 비내림차순)는 모두 엔진이 생성 시점에
-- 이미 막으므로 실제 값으로는 도달할 수 없다. mock 시나리오와 같은 입력을 엔진이 거부하는 것을 대신 확인한다.
const strict = Type.NumberSequence({ strictKeypointOrder = true })
Helper.expectOk(Common.check(strict, NumberSequence.new(0, 1)))
Helper.expectOk(Common.check(strict, sequence({ { 0, 0 }, { 0.5, 0 }, { 0.5, 1 }, { 1, 1 } })))
Helper.expectError(function()
    sequence({ { 0.1, 0 }, { 1, 1 } })
end, "NumberSequence must start at time=0.0")
Helper.expectError(function()
    sequence({ { 0, 0 }, { 0.9, 1 } })
end, "NumberSequence must end at time=1.0")
Helper.expectError(function()
    sequence({ { 0, 0 }, { 0.6, 0 }, { 0.3, 0 }, { 1, 1 } })
end, "NumberSequence: all keypoints must be ordered by time")

return true
