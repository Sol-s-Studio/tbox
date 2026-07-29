--!strict

const Base = require("../../base")
const Types = require("../../types")

-- UDim2 의 X, Y 는 서로 독립적인 UDim 이므로 수치 범위 제약은 축별로 분리한다.
-- (예: 가로는 스케일로 꽉 채우고 세로만 오프셋 상한을 두는 UI 가 흔하다)
-- 반면 scaleOnly / offsetOnly / integerOffsetOnly 는 "이 UDim2 가 어떤 성격의 값인가" 에
-- 대한 제약이므로 두 축에 공통으로 적용한다.
export type TUDim2 = {
    minXScale: number?,
    maxXScale: number?,
    minXOffset: number?,
    maxXOffset: number?,
    minYScale: number?,
    maxYScale: number?,
    minYOffset: number?,
    maxYOffset: number?,
    integerOffsetOnly: boolean?,
    scaleOnly: boolean?,
    offsetOnly: boolean?,
} & Base.TSchema & Types.InnerType<UDim2> & Types.NamedType<"UDim2">
export type TUDim2Options = Types.Merge<{
    minXScale: number?,
    maxXScale: number?,
    minXOffset: number?,
    maxXOffset: number?,
    minYScale: number?,
    maxYScale: number?,
    minYOffset: number?,
    maxYOffset: number?,
    integerOffsetOnly: boolean?,
    scaleOnly: boolean?,
    offsetOnly: boolean?,
}, Base.TSchemaOptions>

const function UDim2(options: TUDim2Options?): TUDim2
    options = options or ({} :: TUDim2Options)
    return Base.SchemaFactory<<TUDim2>>("UDim2", options, {
        minXScale = options.minXScale,
        maxXScale = options.maxXScale,
        minXOffset = options.minXOffset,
        maxXOffset = options.maxXOffset,
        minYScale = options.minYScale,
        maxYScale = options.maxYScale,
        minYOffset = options.minYOffset,
        maxYOffset = options.maxYOffset,
        integerOffsetOnly = options.integerOffsetOnly,
        scaleOnly = options.scaleOnly,
        offsetOnly = options.offsetOnly,
    })
end

const function luauBuilder(_schema: TUDim2): string
    return "UDim2"
end

const function formatter(_schema: TUDim2): string
    return "TUDim2"
end

const function runtimeTypeChecker(_schema: TUDim2, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "UDim2" then
        return function()
            return `UDim2 expected, but got {ty}`
        end
    end
    return nil
end

-- 한 축(UDim) 에 대한 검사. 축별 수치 제약은 인자로 받고, 공통 불리언 제약은 schema 에서 읽는다.
-- 에러 메시지에는 어느 축인지(prefix) 를 남긴다.
const function checkAxis(
    prefix: string,
    schema: TUDim2,
    value: UDim,
    minScale: number?,
    maxScale: number?,
    minOffset: number?,
    maxOffset: number?
): (() -> string)?
    if schema.scaleOnly and value.Offset ~= 0 then
        return function()
            return `{prefix} offset must be zero when scaleOnly is set, but got {value.Offset}`
        end
    end

    if schema.offsetOnly and value.Scale ~= 0 then
        return function()
            return `{prefix} scale must be zero when offsetOnly is set, but got {value.Scale}`
        end
    end

    if schema.integerOffsetOnly and value.Offset % 1 ~= 0 then
        return function()
            return `{prefix} offset must be an integer, but got {value.Offset}`
        end
    end

    if maxScale and value.Scale > maxScale then
        return function()
            return `{prefix} scale too big. maximum allowed {prefix} scale is {maxScale}`
        end
    end

    if minScale and value.Scale < minScale then
        return function()
            return `{prefix} scale too small. minimum allowed {prefix} scale is {minScale}`
        end
    end

    if maxOffset and value.Offset > maxOffset then
        return function()
            return `{prefix} offset too big. maximum allowed {prefix} offset is {maxOffset}`
        end
    end

    if minOffset and value.Offset < minOffset then
        return function()
            return `{prefix} offset too small. minimum allowed {prefix} offset is {minOffset}`
        end
    end

    return nil
end

const function runtimeConstraintChecker(schema: TUDim2, value: UDim2): (() -> string)?
    return checkAxis("x", schema, value.X, schema.minXScale, schema.maxXScale, schema.minXOffset, schema.maxXOffset)
        or checkAxis("y", schema, value.Y, schema.minYScale, schema.maxYScale, schema.minYOffset, schema.maxYOffset)
end

return Base.TypeDefFactory("UDim2", UDim2, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
