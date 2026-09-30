--!strict

const Base = require("../base")
const Types = require("../types")

export type TVector =
    { minMagnitude: number?, maxMagnitude: number?, min: vector?, max: vector? }
    & Base.TSchema
    & Types.InnerType<vector>
    & Types.NamedType<"Vector">
export type TVectorOptions = Types.Merge<
    { minMagnitude: number?, maxMagnitude: number?, min: vector?, max: vector? },
    Base.TSchemaOptions
>

const function Vector(options: TVectorOptions?): TVector
    options = options or ({} :: TVectorOptions)
    return Base.SchemaFactory<<TVector>>("Vector", options, {
        minMagnitude = options.minMagnitude,
        maxMagnitude = options.maxMagnitude,
        min = options.min,
        max = options.max,
    })
end

const function luauBuilder(schema: TVector): string
    return "vector"
end

const function formatter(schema: TVector): string
    return "TVector"
end

const function runtimeTypeChecker(schema: TVector, value: any): (() -> string)?
    const ty = typeof(value)

    -- Roblox 에서는 네이티브 vector 가 곧 Vector3 이라 typeof(vector.create(...)) 가 "Vector3" 이다
    -- (Studio 에서 확인, RobloxApi.md 4절). 같은 값이므로 둘 다 받는다. standalone luau 에서는 "vector" 다.
    if ty ~= "vector" and ty ~= "Vector3" then
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
                return `x value too small. minimum allowed x value is {min.x}`
            end
        elseif value.y < min.y then
            return function()
                return `y value too small. minimum allowed y value is {min.y}`
            end
        elseif value.z < min.z then
            return function()
                return `z value too small. minimum allowed z value is {min.z}`
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
