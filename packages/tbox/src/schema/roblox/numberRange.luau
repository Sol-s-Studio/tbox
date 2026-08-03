--!strict

const Base = require("../../base")
const Types = require("../../types")

-- Min/Max 는 32비트 float 로 저장되므로, 아주 큰 정수는 정밀도가 손실될 수 있다.
export type TNumberRange =
    { min: number?, max: number?, minSpan: number?, maxSpan: number?, disallowEmpty: boolean? }
    & Base.TSchema
    & Types.InnerType<NumberRange>
    & Types.NamedType<"NumberRange">
export type TNumberRangeOptions = Types.Merge<
    { min: number?, max: number?, minSpan: number?, maxSpan: number?, disallowEmpty: boolean? },
    Base.TSchemaOptions
>

const function NumberRange(options: TNumberRangeOptions?): TNumberRange
    options = options or ({} :: TNumberRangeOptions)
    return Base.SchemaFactory<<TNumberRange>>("NumberRange", options, {
        min = options.min,
        max = options.max,
        minSpan = options.minSpan,
        maxSpan = options.maxSpan,
        disallowEmpty = options.disallowEmpty,
    })
end

const function luauBuilder(_schema: TNumberRange): string
    return "NumberRange"
end

const function formatter(_schema: TNumberRange): string
    return "TNumberRange"
end

const function runtimeTypeChecker(_schema: TNumberRange, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "NumberRange" then
        return function()
            return `NumberRange expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TNumberRange, value: NumberRange): (() -> string)?
    -- 엔진이 Min <= Max 를 이미 보장하므로 순서 검사는 하지 않는다
    if schema.disallowEmpty and value.Min == value.Max then
        return function()
            return `NumberRange must not be empty. Min and Max must not be equal`
        end
    end

    if schema.max and value.Max > schema.max then
        return function()
            return `NumberRange.Max too big. maximum allowed value is {schema.max}`
        end
    end

    if schema.min and value.Min < schema.min then
        return function()
            return `NumberRange.Min too small. minimum allowed value is {schema.min}`
        end
    end

    const span = value.Max - value.Min
    if schema.maxSpan and span > schema.maxSpan then
        return function()
            return `NumberRange too wide. maximum allowed span (Max - Min) is {schema.maxSpan}`
        end
    end

    if schema.minSpan and span < schema.minSpan then
        return function()
            return `NumberRange too narrow. minimum allowed span (Max - Min) is {schema.minSpan}`
        end
    end

    return nil
end

return Base.TypeDefFactory("NumberRange", NumberRange, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
