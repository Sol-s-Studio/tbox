--!strict

const Base = require("../../base")
const Types = require("../../types")
-- 이 타입의 필드는 float32 로 저장되므로 숫자 경계를 Util.toFloat32 로 맞춰 비교한다 (util.luau 참고)
const Util = require("../../util")

export type TColorSequenceKeypoint =
    { minTime: number?, maxTime: number? }
    & Base.TSchema
    & Types.InnerType<ColorSequenceKeypoint>
    & Types.NamedType<"ColorSequenceKeypoint">
export type TColorSequenceKeypointOptions = Types.Merge<{ minTime: number?, maxTime: number? }, Base.TSchemaOptions>

const function ColorSequenceKeypoint(options: TColorSequenceKeypointOptions?): TColorSequenceKeypoint
    options = options or ({} :: TColorSequenceKeypointOptions)
    return Base.SchemaFactory<<TColorSequenceKeypoint>>("ColorSequenceKeypoint", options, {
        minTime = options.minTime,
        maxTime = options.maxTime,
    })
end

const function luauBuilder(_schema: TColorSequenceKeypoint): string
    return "ColorSequenceKeypoint"
end

const function formatter(_schema: TColorSequenceKeypoint): string
    return "TColorSequenceKeypoint"
end

const function runtimeTypeChecker(_schema: TColorSequenceKeypoint, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "ColorSequenceKeypoint" then
        return function()
            return `ColorSequenceKeypoint expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TColorSequenceKeypoint, value: ColorSequenceKeypoint): (() -> string)?
    if schema.maxTime and value.Time > Util.toFloat32(schema.maxTime) then
        return function()
            return `time too big. maximum allowed time is {schema.maxTime}`
        end
    end

    if schema.minTime and value.Time < Util.toFloat32(schema.minTime) then
        return function()
            return `time too small. minimum allowed time is {schema.minTime}`
        end
    end

    return nil
end

return Base.TypeDefFactory("ColorSequenceKeypoint", ColorSequenceKeypoint, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
