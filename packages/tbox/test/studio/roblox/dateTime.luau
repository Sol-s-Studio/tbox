--!strict

-- test/schema/roblox/dateTime.luau 의 mock 시나리오를 실제 DateTime 으로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

Helper.expectOk(Type:runtimeTypeCheck(Type.DateTime(), DateTime.now()))
Helper.expectFail(Type:runtimeTypeCheck(Type.DateTime(), 123), "DateTime expected, but got number")
-- os.time() 같은 숫자 타임스탬프는 DateTime 이 아니다
Helper.expectFail(Type:runtimeTypeCheck(Type.DateTime(), os.time()), "DateTime expected, but got number")
-- fromIsoDate 는 파싱에 실패하면 에러 대신 nil 을 돌려주므로, 검사하지 않으면 nil 이 그대로 흘러간다
Helper.expectFail(
    Type:runtimeTypeCheck(Type.DateTime(), DateTime.fromIsoDate("not a date")),
    "DateTime expected, but got nil"
)

const schema = Type.DateTime({ minUnixTimestampMillis = 0, maxUnixTimestampMillis = 1000, wholeSecondsOnly = true })

Helper.expectOk(Common.check(schema, DateTime.fromUnixTimestampMillis(0)))
Helper.expectOk(Common.check(schema, DateTime.fromUnixTimestamp(1)))
Helper.expectFail(
    Common.check(schema, DateTime.fromUnixTimestampMillis(1500)),
    "datetime too far in the future. maximum allowed unix timestamp millis is 1000"
)
Helper.expectFail(
    Common.check(schema, DateTime.fromUnixTimestampMillis(-500)),
    "datetime too far in the past. minimum allowed unix timestamp millis is 0"
)

const wholeSecondsSchema = Type.DateTime({ wholeSecondsOnly = true })
Helper.expectFail(
    Common.check(wholeSecondsSchema, DateTime.fromUnixTimestampMillis(1234)),
    "datetime must not have sub-second precision, but got 1234 unix timestamp millis"
)
Helper.expectFail(
    Common.check(wholeSecondsSchema, DateTime.fromUniversalTime(2020, 1, 1, 0, 0, 0, 500)),
    "datetime must not have sub-second precision, but got 1577836800500 unix timestamp millis"
)
-- fromUnixTimestamp 는 소수 초를 버린다 (Studio 에서 확인: fromUnixTimestamp(1.5).UnixTimestampMillis == 1000).
-- 즉 초 단위 생성자로 만든 값은 wholeSecondsOnly 를 항상 통과한다.
Helper.expectEqual(DateTime.fromUnixTimestamp(1.5).UnixTimestampMillis, 1000)
Helper.expectOk(Common.check(wholeSecondsSchema, DateTime.fromUnixTimestamp(1.5)))

-- 지원 범위 경계값은 실제로 만들 수 있고 withinRobloxRange 를 통과한다
const rangedSchema = Type.DateTime({ withinRobloxRange = true })
Helper.expectOk(Common.check(rangedSchema, DateTime.fromUnixTimestampMillis(0)))
Helper.expectOk(Common.check(rangedSchema, DateTime.fromUnixTimestampMillis(253402300799999)))
Helper.expectOk(Common.check(rangedSchema, DateTime.fromUnixTimestampMillis(-17987443200000)))

-- mock 의 "범위 밖 DateTime" 은 실제로 만들 수 없다. 엔진이 생성 시점에 거부하므로
-- withinRobloxRange 의 실패 분기는 실제 DateTime 에 대해 도달 불가능하다.
const rangeError = "UnixTimestampMillis should be between -17987443200000 and 253402300799999."
Helper.expectError(function()
    DateTime.fromUnixTimestampMillis(300000000000000)
end, rangeError)
Helper.expectError(function()
    DateTime.fromUnixTimestampMillis(253402300800000)
end, rangeError)
Helper.expectError(function()
    DateTime.fromUnixTimestampMillis(-17987443200001)
end, rangeError)

return true
