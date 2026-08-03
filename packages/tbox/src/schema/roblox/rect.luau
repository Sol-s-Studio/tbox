--!strict

const Base = require("../../base")
const Types = require("../../types")

export type TRect = {
    min: Vector2?,
    max: Vector2?,
    minWidth: number?,
    maxWidth: number?,
    minHeight: number?,
    maxHeight: number?,
    normalizedOnly: boolean?,
} & Base.TSchema & Types.InnerType<Rect> & Types.NamedType<"Rect">
export type TRectOptions = Types.Merge<{
    min: Vector2?,
    max: Vector2?,
    minWidth: number?,
    maxWidth: number?,
    minHeight: number?,
    maxHeight: number?,
    normalizedOnly: boolean?,
}, Base.TSchemaOptions>

const function Rect(options: TRectOptions?): TRect
    options = options or ({} :: TRectOptions)
    return Base.SchemaFactory<<TRect>>("Rect", options, {
        min = options.min,
        max = options.max,
        minWidth = options.minWidth,
        maxWidth = options.maxWidth,
        minHeight = options.minHeight,
        maxHeight = options.maxHeight,
        normalizedOnly = options.normalizedOnly,
    })
end

const function luauBuilder(_schema: TRect): string
    return "Rect"
end

const function formatter(_schema: TRect): string
    return "TRect"
end

const function runtimeTypeChecker(_schema: TRect, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "Rect" then
        return function()
            return `Rect expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TRect, value: Rect): (() -> string)?
    -- Rect.new 는 Min <= Max 를 강제하지 않으므로, 필요하면 여기서 직접 검사한다
    if schema.normalizedOnly then
        if value.Min.X > value.Max.X or value.Min.Y > value.Max.Y then
            return function()
                return `rect must be normalized, expected Min.X <= Max.X and Min.Y <= Max.Y`
            end
        end
    end

    const max = schema.max
    if max then
        if value.Max.X > max.X then
            return function()
                return `max.x too big. maximum allowed max.x value is {max.X}`
            end
        elseif value.Max.Y > max.Y then
            return function()
                return `max.y too big. maximum allowed max.y value is {max.Y}`
            end
        end
    end

    const min = schema.min
    if min then
        if value.Min.X < min.X then
            return function()
                return `min.x too small. minimum allowed min.x value is {min.X}`
            end
        elseif value.Min.Y < min.Y then
            return function()
                return `min.y too small. minimum allowed min.y value is {min.Y}`
            end
        end
    end

    if schema.maxWidth and value.Width > schema.maxWidth then
        return function()
            return `width too big. maximum allowed width is {schema.maxWidth}`
        end
    end

    if schema.minWidth and value.Width < schema.minWidth then
        return function()
            return `width too small. minimum allowed width is {schema.minWidth}`
        end
    end

    if schema.maxHeight and value.Height > schema.maxHeight then
        return function()
            return `height too big. maximum allowed height is {schema.maxHeight}`
        end
    end

    if schema.minHeight and value.Height < schema.minHeight then
        return function()
            return `height too small. minimum allowed height is {schema.minHeight}`
        end
    end

    return nil
end

return Base.TypeDefFactory("Rect", Rect, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
