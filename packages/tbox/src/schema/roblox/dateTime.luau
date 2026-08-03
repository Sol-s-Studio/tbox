--!strict

const Base = require("../../base")
const Types = require("../../types")

-- Roblox 가 지원하는 DateTime 범위 (문서 명시, 대략 서기 1400 ~ 9999년)
const MIN_UNIX_TIMESTAMP = -17987443200
const MAX_UNIX_TIMESTAMP = 253402300799
const MIN_UNIX_TIMESTAMP_MILLIS = MIN_UNIX_TIMESTAMP * 1000
const MAX_UNIX_TIMESTAMP_MILLIS = (MAX_UNIX_TIMESTAMP + 1) * 1000 - 1

export type TDateTime = {
    minUnixTimestampMillis: number?,
    maxUnixTimestampMillis: number?,
    wholeSecondsOnly: boolean?,
    withinRobloxRange: boolean?,
} & Base.TSchema & Types.InnerType<DateTime> & Types.NamedType<"DateTime">
export type TDateTimeOptions = Types.Merge<{
    minUnixTimestampMillis: number?,
    maxUnixTimestampMillis: number?,
    wholeSecondsOnly: boolean?,
    withinRobloxRange: boolean?,
}, Base.TSchemaOptions>

const function DateTimeType(options: TDateTimeOptions?): TDateTime
    options = options or ({} :: TDateTimeOptions)
    return Base.SchemaFactory<<TDateTime>>("DateTime", options, {
        minUnixTimestampMillis = options.minUnixTimestampMillis,
        maxUnixTimestampMillis = options.maxUnixTimestampMillis,
        wholeSecondsOnly = options.wholeSecondsOnly,
        withinRobloxRange = options.withinRobloxRange,
    })
end

const function luauBuilder(_schema: TDateTime): string
    return "DateTime"
end

const function formatter(_schema: TDateTime): string
    return "TDateTime"
end

const function runtimeTypeChecker(_schema: TDateTime, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "DateTime" then
        return function()
            return `DateTime expected, but got {ty}`
        end
    end
    return nil
end

-- 주의: notFuture / notPast 같은 "검사 시점(현재 시각)에 의존하는" 옵션은 의도적으로 넣지 않는다.
-- 스키마 검사는 동일한 입력에 대해 항상 동일한 결과를 내는 순수 함수여야 하는데,
-- 현재 시각과 비교하면 같은 값이 호출 시점에 따라 통과/실패가 뒤바뀌게 된다.
const function runtimeConstraintChecker(schema: TDateTime, value: DateTime): (() -> string)?
    const millis = value.UnixTimestampMillis

    if schema.maxUnixTimestampMillis and millis > schema.maxUnixTimestampMillis then
        return function()
            return `datetime too far in the future. maximum allowed unix timestamp millis is {schema.maxUnixTimestampMillis}`
        end
    end

    if schema.minUnixTimestampMillis and millis < schema.minUnixTimestampMillis then
        return function()
            return `datetime too far in the past. minimum allowed unix timestamp millis is {schema.minUnixTimestampMillis}`
        end
    end

    if schema.wholeSecondsOnly and millis % 1000 ~= 0 then
        return function()
            return `datetime must not have sub-second precision, but got {millis} unix timestamp millis`
        end
    end

    if schema.withinRobloxRange then
        if millis > MAX_UNIX_TIMESTAMP_MILLIS or millis < MIN_UNIX_TIMESTAMP_MILLIS then
            return function()
                return `datetime out of roblox supported range ({MIN_UNIX_TIMESTAMP_MILLIS} ~ {MAX_UNIX_TIMESTAMP_MILLIS} unix timestamp millis)`
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("DateTime", DateTimeType, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
