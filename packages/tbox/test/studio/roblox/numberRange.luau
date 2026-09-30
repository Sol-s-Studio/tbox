--!strict

-- test/schema/roblox/numberRange.luau 의 mock 시나리오를 실제 NumberRange 로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

Helper.expectOk(Type:runtimeTypeCheck(Type.NumberRange(), NumberRange.new(1, 4)))
Helper.expectFail(Type:runtimeTypeCheck(Type.NumberRange(), 123), "NumberRange expected, but got number")
Helper.expectFail(
    Type:runtimeTypeCheck(Type.NumberRange(), NumberSequence.new(1)),
    "NumberRange expected, but got NumberSequence"
)

const schema = Type.NumberRange({ min = 0, max = 10, minSpan = 1, maxSpan = 5, disallowEmpty = true })

Helper.expectOk(Common.check(schema, NumberRange.new(1, 4)))
Helper.expectFail(
    Common.check(schema, NumberRange.new(5, 5)),
    "NumberRange must not be empty. Min and Max must not be equal"
)
-- 인자 하나짜리 생성자는 Min == Max 인 빈 범위다
Helper.expectFail(
    Common.check(schema, NumberRange.new(5)),
    "NumberRange must not be empty. Min and Max must not be equal"
)
Helper.expectFail(Common.check(schema, NumberRange.new(1, 11)), "NumberRange.Max too big. maximum allowed value is 10")
Helper.expectFail(Common.check(schema, NumberRange.new(-1, 1)), "NumberRange.Min too small. minimum allowed value is 0")
Helper.expectFail(
    Common.check(schema, NumberRange.new(1, 7)),
    "NumberRange too wide. maximum allowed span (Max - Min) is 5"
)
Helper.expectFail(
    Common.check(schema, NumberRange.new(1, 1.5)),
    "NumberRange too narrow. minimum allowed span (Max - Min) is 1"
)

-- Min > Max 는 엔진이 생성 시점에 거부한다 (src 가 순서 검사를 하지 않는 근거)
Helper.expectError(function()
    NumberRange.new(5, 1)
end, "NumberRange: invalid range")

-- Min/Max 는 32비트 float 로 저장된다. NumberRange.new(0, 0.1).Max 는 0.10000000149011612 라서
-- 옵션으로 준 64비트 0.1 보다 크다. "0.1 까지 허용" 이라는 스키마가 바로 그 0.1 로 만든 범위를 거부한다.
Helper.pending("NumberRange.new(0, 0.1) should satisfy max = 0.1 (Min/Max are stored as float32)", function()
    Helper.expectOk(Common.check(Type.NumberRange({ max = 0.1 }), NumberRange.new(0, 0.1)))
end)

return true
