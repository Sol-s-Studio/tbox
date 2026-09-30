--!strict

-- test/schema/roblox/colorSequence.luau 의 mock 시나리오를 실제 ColorSequence 로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

const black = Color3.new(0, 0, 0)
const white = Color3.new(1, 1, 1)

const function keypoints(times: { number }): { ColorSequenceKeypoint }
    const result = {}
    for _, time in times do
        table.insert(result, ColorSequenceKeypoint.new(time, white))
    end
    return result
end

Helper.expectOk(Type:runtimeTypeCheck(Type.ColorSequence(), ColorSequence.new(white)))
Helper.expectFail(Type:runtimeTypeCheck(Type.ColorSequence(), 123), "ColorSequence expected, but got number")
Helper.expectFail(
    Type:runtimeTypeCheck(Type.ColorSequence(), NumberSequence.new(1)),
    "ColorSequence expected, but got NumberSequence"
)
Helper.expectFail(Type:runtimeTypeCheck(Type.ColorSequence(), white), "ColorSequence expected, but got Color3")

const schema = Type.ColorSequence({ minKeypoints = 2, maxKeypoints = 3 })
Helper.expectOk(Common.check(schema, ColorSequence.new(black, white)))
-- 단색 생성자도 키포인트 2개(0, 1)로 펼쳐진다
Helper.expectEqual(#ColorSequence.new(white).Keypoints, 2)
Helper.expectOk(Common.check(schema, ColorSequence.new(white)))
Helper.expectFail(
    Common.check(schema, ColorSequence.new(keypoints({ 0, 0.25, 0.5, 1 }))),
    "too many keypoints. maximum allowed keypoint count is 3"
)

-- mock 의 "키포인트 1개" 시나리오는 실제로 만들 수 없다. 엔진이 생성 시점에 거부한다.
-- 대신 minKeypoints 를 3 으로 올려 같은 분기를 실제 값으로 태운다.
Helper.expectError(function()
    ColorSequence.new(keypoints({ 0 }))
end, "ColorSequence: requires at least 2 keypoints")
Helper.expectFail(
    Common.check(Type.ColorSequence({ minKeypoints = 3 }), ColorSequence.new(black, white)),
    "too few keypoints. minimum allowed keypoint count is 3"
)

-- RobloxApi.md 에서 "미확인" 으로 남겨둔 최대 키포인트 20개 제한은 실제로 존재한다 (21개부터 생성 에러)
const twenty = {}
for index = 0, 19 do
    table.insert(twenty, index / 19)
end
Helper.expectEqual(#ColorSequence.new(keypoints(twenty)).Keypoints, 20)
const twentyOne = {}
for index = 0, 20 do
    table.insert(twentyOne, index / 20)
end
Helper.expectError(function()
    ColorSequence.new(keypoints(twentyOne))
end, "ColorSequence.new(): table is too long.")

-- strictKeypointOrder 가 잡으려는 규칙(첫 Time 0 / 마지막 Time 1 / 비내림차순 / 최소 2개)은 전부 엔진이
-- 생성 시점에 이미 강제한다. 즉 실제 ColorSequence 값으로는 strict 검사의 실패 분기에 도달할 수 없고,
-- mock 시나리오 대신 엔진이 같은 입력을 거부한다는 것을 확인한다.
const strict = Type.ColorSequence({ strictKeypointOrder = true })
Helper.expectOk(Common.check(strict, ColorSequence.new(black, white)))
-- 같은 Time 이 연속되는 것(비내림차순)은 엔진도 허용하고 strict 도 통과해야 한다
Helper.expectOk(Common.check(strict, ColorSequence.new(keypoints({ 0, 0.5, 0.5, 1 }))))
Helper.expectError(function()
    ColorSequence.new(keypoints({ 0.1, 1 }))
end, "ColorSequence must start at time=0.0")
Helper.expectError(function()
    ColorSequence.new(keypoints({ 0, 0.9 }))
end, "ColorSequence must end at time=1.0")
Helper.expectError(function()
    ColorSequence.new(keypoints({ 0, 0.6, 0.3, 1 }))
end, "ColorSequence: all keypoints must be ordered by time")

return true
