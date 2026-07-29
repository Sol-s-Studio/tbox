--!strict

const Base = require("../../base")
const Types = require("../../types")

export type TUDim = {
    minScale: number?,
    maxScale: number?,
    minOffset: number?,
    maxOffset: number?,
    integerOffsetOnly: boolean?,
    scaleOnly: boolean?,
    offsetOnly: boolean?,
} & Base.TSchema & Types.InnerType<UDim> & Types.NamedType<"UDim">
export type TUDimOptions = Types.Merge<{
    minScale: number?,
    maxScale: number?,
    minOffset: number?,
    maxOffset: number?,
    integerOffsetOnly: boolean?,
    scaleOnly: boolean?,
    offsetOnly: boolean?,
}, Base.TSchemaOptions>

const function UDim(options: TUDimOptions?): TUDim
    options = options or ({} :: TUDimOptions)
    return Base.SchemaFactory<<TUDim>>("UDim", options, {
        minScale = options.minScale,
        maxScale = options.maxScale,
        minOffset = options.minOffset,
        maxOffset = options.maxOffset,
        integerOffsetOnly = options.integerOffsetOnly,
        scaleOnly = options.scaleOnly,
        offsetOnly = options.offsetOnly,
    })
end

const function luauBuilder(_schema: TUDim): string
    return "UDim"
end

const function formatter(_schema: TUDim): string
    return "TUDim"
end

const function runtimeTypeChecker(_schema: TUDim, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "UDim" then
        return function()
            return `UDim expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TUDim, value: UDim): (() -> string)?
    -- scaleOnly / offsetOnly 는 생성자가 강제하지 않는 조합 제약이라 여기서 검사한다
    if schema.scaleOnly and value.Offset ~= 0 then
        return function()
            return `offset must be zero when scaleOnly is set, but got {value.Offset}`
        end
    end

    if schema.offsetOnly and value.Scale ~= 0 then
        return function()
            return `scale must be zero when offsetOnly is set, but got {value.Scale}`
        end
    end

    if schema.integerOffsetOnly and value.Offset % 1 ~= 0 then
        return function()
            return `offset must be an integer, but got {value.Offset}`
        end
    end

    if schema.maxScale and value.Scale > schema.maxScale then
        return function()
            return `scale too big. maximum allowed scale is {schema.maxScale}`
        end
    end

    if schema.minScale and value.Scale < schema.minScale then
        return function()
            return `scale too small. minimum allowed scale is {schema.minScale}`
        end
    end

    if schema.maxOffset and value.Offset > schema.maxOffset then
        return function()
            return `offset too big. maximum allowed offset is {schema.maxOffset}`
        end
    end

    if schema.minOffset and value.Offset < schema.minOffset then
        return function()
            return `offset too small. minimum allowed offset is {schema.minOffset}`
        end
    end

    return nil
end

return Base.TypeDefFactory("UDim", UDim, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
