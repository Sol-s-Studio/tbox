--!strict

const Base = require("../../base")
const Types = require("../../types")

export type TNumberSequenceKeypoint = {
    minTime: number?,
    maxTime: number?,
    minValue: number?,
    maxValue: number?,
    maxEnvelope: number?,
    envelopeMustBeZero: boolean?,
} & Base.TSchema & Types.InnerType<NumberSequenceKeypoint> & Types.NamedType<"NumberSequenceKeypoint">
export type TNumberSequenceKeypointOptions = Types.Merge<{
    minTime: number?,
    maxTime: number?,
    minValue: number?,
    maxValue: number?,
    maxEnvelope: number?,
    envelopeMustBeZero: boolean?,
}, Base.TSchemaOptions>

const function NumberSequenceKeypoint(options: TNumberSequenceKeypointOptions?): TNumberSequenceKeypoint
    options = options or ({} :: TNumberSequenceKeypointOptions)
    return Base.SchemaFactory<<TNumberSequenceKeypoint>>("NumberSequenceKeypoint", options, {
        minTime = options.minTime,
        maxTime = options.maxTime,
        minValue = options.minValue,
        maxValue = options.maxValue,
        maxEnvelope = options.maxEnvelope,
        envelopeMustBeZero = options.envelopeMustBeZero,
    })
end

const function luauBuilder(_schema: TNumberSequenceKeypoint): string
    return "NumberSequenceKeypoint"
end

const function formatter(_schema: TNumberSequenceKeypoint): string
    return "TNumberSequenceKeypoint"
end

const function runtimeTypeChecker(_schema: TNumberSequenceKeypoint, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "NumberSequenceKeypoint" then
        return function()
            return `NumberSequenceKeypoint expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TNumberSequenceKeypoint, value: NumberSequenceKeypoint): (() -> string)?
    if schema.maxTime and value.Time > schema.maxTime then
        return function()
            return `NumberSequenceKeypoint.Time too big. maximum allowed value is {schema.maxTime}`
        end
    end

    if schema.minTime and value.Time < schema.minTime then
        return function()
            return `NumberSequenceKeypoint.Time too small. minimum allowed value is {schema.minTime}`
        end
    end

    if schema.maxValue and value.Value > schema.maxValue then
        return function()
            return `NumberSequenceKeypoint.Value too big. maximum allowed value is {schema.maxValue}`
        end
    end

    if schema.minValue and value.Value < schema.minValue then
        return function()
            return `NumberSequenceKeypoint.Value too small. minimum allowed value is {schema.minValue}`
        end
    end

    if schema.maxEnvelope and value.Envelope > schema.maxEnvelope then
        return function()
            return `NumberSequenceKeypoint.Envelope too big. maximum allowed value is {schema.maxEnvelope}`
        end
    end

    if schema.envelopeMustBeZero and value.Envelope ~= 0 then
        return function()
            return `NumberSequenceKeypoint.Envelope must be zero, but got {value.Envelope}`
        end
    end

    return nil
end

return Base.TypeDefFactory("NumberSequenceKeypoint", NumberSequenceKeypoint, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
