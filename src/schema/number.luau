--!strict

const Base = require("../base")
const Types = require("../types")

export type TNumber =
    { min: number?, max: number?, notInf: boolean?, notNan: boolean?, isFinite: boolean? }
    & Base.TSchema
    & Types.InnerType<number>
export type TNumberOptions = Types.Merge<
    { min: number?, max: number?, notInf: boolean?, notNan: boolean?, isFinite: boolean? },
    Base.TSchemaOptions
>

const function Number(options: TNumberOptions?): TNumber
    options = options or ({} :: TNumberOptions)
    return Base.SchemaFactory<<TNumber>>("Number", options, {
        min = options.min,
        max = options.max,
        notInf = options.notInf,
        notNan = options.notNan,
        isFinite = options.isFinite,
    })
end

const function luauBuilder(_schema: TNumber): string
    return "number"
end

const function formatter(_schema: TNumber): string
    return "TNumber"
end

const function runtimeTypeChecker(schema: TNumber, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "number" then
        return function()
            return `number expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TNumber, value: number): (() -> string)?
    if schema.notInf and math.isinf(value) then
        return function()
            return `inf is not allowed`
        end
    end

    if schema.notNan and math.isnan(value) then
        return function()
            return `nan is not allowed`
        end
    end

    if schema.max and value > schema.max then
        return function()
            return `number too big. maximum allowed value is {schema.max}`
        end
    end

    if schema.min and value < schema.min then
        return function()
            return `number too small. minimum allowed value is {schema.max}`
        end
    end

    if schema.isFinite ~= nil then
        const isFinite = math.isfinite(value)
        if schema.isFinite ~= isFinite then
            return function()
                if schema.isFinite then
                    return `value must be a finite number, but a non-finite value was provided`
                else
                    return `value must be a non-finite number, but a finite value was provided`
                end
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("Number", Number, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
