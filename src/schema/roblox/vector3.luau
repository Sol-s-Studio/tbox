--!strict

const Base = require("../../base")
const Types = require("../../types")

export type TVector3 = {
    min: Vector3?,
    max: Vector3?,
    minMagnitude: number?,
    maxMagnitude: number?,
    integerOnly: boolean?,
    notNan: boolean?,
} & Base.TSchema & Types.InnerType<Vector3> & Types.NamedType<"Vector3">
export type TVector3Options = Types.Merge<{
    min: Vector3?,
    max: Vector3?,
    minMagnitude: number?,
    maxMagnitude: number?,
    integerOnly: boolean?,
    notNan: boolean?,
}, Base.TSchemaOptions>

const function Vector3(options: TVector3Options?): TVector3
    options = options or ({} :: TVector3Options)
    return Base.SchemaFactory<<TVector3>>("Vector3", options, {
        min = options.min,
        max = options.max,
        minMagnitude = options.minMagnitude,
        maxMagnitude = options.maxMagnitude,
        integerOnly = options.integerOnly,
        notNan = options.notNan,
    })
end

const function luauBuilder(_schema: TVector3): string
    return "Vector3"
end

const function formatter(_schema: TVector3): string
    return "TVector3"
end

const function runtimeTypeChecker(_schema: TVector3, value: any): (() -> string)?
    const ty = typeof(value)

    if ty ~= "Vector3" then
        return function()
            return `Vector3 expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TVector3, value: Vector3): (() -> string)?
    if schema.notNan then
        if value.X ~= value.X then
            return function()
                return `x component must not be nan`
            end
        elseif value.Y ~= value.Y then
            return function()
                return `y component must not be nan`
            end
        elseif value.Z ~= value.Z then
            return function()
                return `z component must not be nan`
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
        elseif value.Z % 1 ~= 0 then
            return function()
                return `z component must be an integer, but got {value.Z}`
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
                return `Vector3 too long. maximum allowed magnitude is {schema.maxMagnitude}`
            end
        end
    end
    if schema.minMagnitude then
        if magnitude == nil then
            magnitude = value.Magnitude
        end
        if (magnitude :: number) < schema.minMagnitude then
            return function()
                return `Vector3 too short. minimum allowed magnitude is {schema.minMagnitude}`
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
        elseif value.Z > max.Z then
            return function()
                return `z value too big. maximum allowed z value is {max.Z}`
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
        elseif value.Z < min.Z then
            return function()
                return `z value too small. minimum allowed z value is {min.Z}`
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("Vector3", Vector3, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
