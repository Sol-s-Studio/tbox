--!strict

const Base = require("../../base")
const Types = require("../../types")

export type TVector2 = {
    min: Vector2?,
    max: Vector2?,
    minMagnitude: number?,
    maxMagnitude: number?,
    integerOnly: boolean?,
    notNan: boolean?,
} & Base.TSchema & Types.InnerType<Vector2> & Types.NamedType<"Vector2">
export type TVector2Options = Types.Merge<{
    min: Vector2?,
    max: Vector2?,
    minMagnitude: number?,
    maxMagnitude: number?,
    integerOnly: boolean?,
    notNan: boolean?,
}, Base.TSchemaOptions>

const function Vector2(options: TVector2Options?): TVector2
    options = options or ({} :: TVector2Options)
    return Base.SchemaFactory<<TVector2>>("Vector2", options, {
        min = options.min,
        max = options.max,
        minMagnitude = options.minMagnitude,
        maxMagnitude = options.maxMagnitude,
        integerOnly = options.integerOnly,
        notNan = options.notNan,
    })
end

const function luauBuilder(_schema: TVector2): string
    return "Vector2"
end

const function formatter(_schema: TVector2): string
    return "TVector2"
end

const function runtimeTypeChecker(_schema: TVector2, value: any): (() -> string)?
    const ty = typeof(value)

    if ty ~= "Vector2" then
        return function()
            return `Vector2 expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TVector2, value: Vector2): (() -> string)?
    if schema.notNan then
        if value.X ~= value.X then
            return function()
                return `x component must not be nan`
            end
        elseif value.Y ~= value.Y then
            return function()
                return `y component must not be nan`
            end
        end
    end

    if schema.integerOnly then
        if value.X % 1 ~= 0 then
            return function()
                return `x component must be an integer, but got {value.X}`
            end
        elseif value.Y % 1 ~= 0 then
            return function()
                return `y component must be an integer, but got {value.Y}`
            end
        end
    end

    -- magnitude 는 필요할 때만 계산해 재사용한다
    local magnitude: number?

    if schema.maxMagnitude then
        if magnitude == nil then
            magnitude = value.Magnitude
        end
        if (magnitude :: number) > schema.maxMagnitude then
            return function()
                return `Vector2 too long. maximum allowed magnitude is {schema.maxMagnitude}`
            end
        end
    end
    if schema.minMagnitude then
        if magnitude == nil then
            magnitude = value.Magnitude
        end
        if (magnitude :: number) < schema.minMagnitude then
            return function()
                return `Vector2 too short. minimum allowed magnitude is {schema.minMagnitude}`
            end
        end
    end

    const max = schema.max
    if max then
        if value.X > max.X then
            return function()
                return `x value too big. maximum allowed x value is {max.X}`
            end
        elseif value.Y > max.Y then
            return function()
                return `y value too big. maximum allowed y value is {max.Y}`
            end
        end
    end
    const min = schema.min
    if min then
        if value.X < min.X then
            return function()
                return `x value too small. minimum allowed x value is {min.X}`
            end
        elseif value.Y < min.Y then
            return function()
                return `y value too small. minimum allowed y value is {min.Y}`
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("Vector2", Vector2, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
