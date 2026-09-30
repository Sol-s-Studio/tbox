--!strict

const Base = require("../../base")
const Types = require("../../types")

export type TRegion3 = {
    minSize: Vector3?,
    maxSize: Vector3?,
    maxVolume: number?,
} & Base.TSchema & Types.InnerType<Region3> & Types.NamedType<"Region3">
export type TRegion3Options = Types.Merge<{
    minSize: Vector3?,
    maxSize: Vector3?,
    maxVolume: number?,
}, Base.TSchemaOptions>

const function Region3(options: TRegion3Options?): TRegion3
    options = options or ({} :: TRegion3Options)
    return Base.SchemaFactory<<TRegion3>>("Region3", options, {
        minSize = options.minSize,
        maxSize = options.maxSize,
        maxVolume = options.maxVolume,
    })
end

const function luauBuilder(_schema: TRegion3): string
    return "Region3"
end

const function formatter(_schema: TRegion3): string
    return "TRegion3"
end

const function runtimeTypeChecker(_schema: TRegion3, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "Region3" then
        return function()
            return `Region3 expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TRegion3, value: Region3): (() -> string)?
    -- Region3 은 Min/Max 프로퍼티가 없으므로 Size 성분으로만 검사한다
    const max = schema.maxSize
    if max then
        if value.Size.X > max.X then
            return function()
                return `size.x too big. maximum allowed size.x value is {max.X}`
            end
        elseif value.Size.Y > max.Y then
            return function()
                return `size.y too big. maximum allowed size.y value is {max.Y}`
            end
        elseif value.Size.Z > max.Z then
            return function()
                return `size.z too big. maximum allowed size.z value is {max.Z}`
            end
        end
    end

    const min = schema.minSize
    if min then
        if value.Size.X < min.X then
            return function()
                return `size.x too small. minimum allowed size.x value is {min.X}`
            end
        elseif value.Size.Y < min.Y then
            return function()
                return `size.y too small. minimum allowed size.y value is {min.Y}`
            end
        elseif value.Size.Z < min.Z then
            return function()
                return `size.z too small. minimum allowed size.z value is {min.Z}`
            end
        end
    end

    if schema.maxVolume then
        -- Region3.new 는 뒤집힌 모서리(min > max)를 정규화하지 않고 음수 Size 로 저장한다 (Studio 에서 확인,
        -- RobloxApi.md 4절). 음수 축이 홀수 개면 곱이 음수가 되어 어떤 크기든 통과하므로 절댓값으로 비교한다.
        const volume = math.abs(value.Size.X * value.Size.Y * value.Size.Z)
        if volume > schema.maxVolume then
            return function()
                return `volume too big. maximum allowed volume is {schema.maxVolume}`
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("Region3", Region3, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
