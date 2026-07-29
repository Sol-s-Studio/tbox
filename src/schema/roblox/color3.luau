--!strict

const Base = require("../../base")
const Types = require("../../types")

export type TColor3 =
    { min: Color3?, max: Color3?, clampedOnly: boolean?, notNan: boolean? }
    & Base.TSchema
    & Types.InnerType<Color3>
    & Types.NamedType<"Color3">
export type TColor3Options = Types.Merge<
    { min: Color3?, max: Color3?, clampedOnly: boolean?, notNan: boolean? },
    Base.TSchemaOptions
>

const function Color3(options: TColor3Options?): TColor3
    options = options or ({} :: TColor3Options)
    return Base.SchemaFactory<<TColor3>>("Color3", options, {
        min = options.min,
        max = options.max,
        clampedOnly = options.clampedOnly,
        notNan = options.notNan,
    })
end

const function luauBuilder(_schema: TColor3): string
    return "Color3"
end

const function formatter(_schema: TColor3): string
    return "TColor3"
end

const function runtimeTypeChecker(_schema: TColor3, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "Color3" then
        return function()
            return `Color3 expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TColor3, value: Color3): (() -> string)?
    if schema.notNan then
        -- Color3.new 은 nan 성분도 그대로 저장한다
        if value.R ~= value.R or value.G ~= value.G or value.B ~= value.B then
            return function()
                return `nan is not allowed`
            end
        end
    end

    if schema.clampedOnly then
        -- Color3.new 은 0~1 범위 밖 값도 그대로 저장하므로 별도로 검사해야 한다
        if value.R < 0 or value.R > 1 or value.G < 0 or value.G > 1 or value.B < 0 or value.B > 1 then
            return function()
                return `color components must be within 0 and 1`
            end
        end
    end

    const max = schema.max
    if max then
        if value.R > max.R then
            return function()
                return `r value too big. maximum allowed r value is {max.R}`
            end
        elseif value.G > max.G then
            return function()
                return `g value too big. maximum allowed g value is {max.G}`
            end
        elseif value.B > max.B then
            return function()
                return `b value too big. maximum allowed b value is {max.B}`
            end
        end
    end

    const min = schema.min
    if min then
        if value.R < min.R then
            return function()
                return `r value too small. minimum allowed r value is {min.R}`
            end
        elseif value.G < min.G then
            return function()
                return `g value too small. minimum allowed g value is {min.G}`
            end
        elseif value.B < min.B then
            return function()
                return `b value too small. minimum allowed b value is {min.B}`
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("Color3", Color3, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
