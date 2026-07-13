--!strict

const Base = require("../base")
const Types = require("../types")

export type TVector =
    { minMagnitude: number?, maxMagnitude: number?, min: vector?, max: vector? }
    & Base.TSchema
    & Types.InnerType<vector>
export type TVectorOptions = Types.Merge<
    { minMagnitude: number?, maxMagnitude: number?, min: vector?, max: vector? },
    Base.TSchemaOptions
>

const function Vector(options: TVectorOptions?): TVector
    options = options or ({} :: TVectorOptions)
    return Base.SchemaFactory<<TVector>>("Vector", options, {})
end

const function luauBuilder(schema: TVector): string
    return "vector"
end

const function formatter(schema: TVector): string
    return "TVector"
end

const function runtimeTypeChecker(schema: TVector, value: any): (() -> string)?
    const ty = typeof(value)

    if ty ~= "vector" then
        return function()
            return `vector expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TVector, value: vector): (() -> string)?
    local magnitude: number?

    if schema.maxMagnitude then
        if magnitude == nil then
            magnitude = vector.magnitude(value)
        end
        if (magnitude :: number) > schema.maxMagnitude then
            return function()
                return `vector too long. maximum allowed magnitude is {schema.maxMagnitude}`
            end
        end
    end
    if schema.minMagnitude then
        if magnitude == nil then
            magnitude = vector.magnitude(value)
        end
        if (magnitude :: number) < schema.minMagnitude then
            return function()
                return `vector too short. minimum allowed magnitude is {schema.minMagnitude}`
            end
        end
    end
    const max = schema.max
    if max then
        if value.x > max.x then
            return function()
                return `x value too big. maximum allowed x value is {max.x}`
            end
        elseif value.y > max.y then
            return function()
                return `y value too big. maximum allowed y value is {max.y}`
            end
        elseif value.z > max.z then
            return function()
                return `z value too big. maximum allowed z value is {max.z}`
            end
        end
    end
    const min = schema.min
    if min then
        if value.x < min.x then
            return function()
                return `x value too big. minimum allowed x value is {min.x}`
            end
        elseif value.y < min.y then
            return function()
                return `y value too big. minimum allowed y value is {min.y}`
            end
        elseif value.z < min.z then
            return function()
                return `z value too big. minimum allowed z value is {min.z}`
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("Vector", Vector, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
