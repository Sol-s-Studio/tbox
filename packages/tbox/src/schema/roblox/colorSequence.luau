--!strict

const Base = require("../../base")
const Types = require("../../types")

export type TColorSequence =
    { minKeypoints: number?, maxKeypoints: number?, strictKeypointOrder: boolean? }
    & Base.TSchema
    & Types.InnerType<ColorSequence>
    & Types.NamedType<"ColorSequence">
export type TColorSequenceOptions = Types.Merge<
    { minKeypoints: number?, maxKeypoints: number?, strictKeypointOrder: boolean? },
    Base.TSchemaOptions
>

const function ColorSequence(options: TColorSequenceOptions?): TColorSequence
    options = options or ({} :: TColorSequenceOptions)
    return Base.SchemaFactory<<TColorSequence>>("ColorSequence", options, {
        minKeypoints = options.minKeypoints,
        maxKeypoints = options.maxKeypoints,
        strictKeypointOrder = options.strictKeypointOrder,
    })
end

const function luauBuilder(_schema: TColorSequence): string
    return "ColorSequence"
end

const function formatter(_schema: TColorSequence): string
    return "TColorSequence"
end

const function runtimeTypeChecker(_schema: TColorSequence, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "ColorSequence" then
        return function()
            return `ColorSequence expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TColorSequence, value: ColorSequence): (() -> string)?
    const keypoints = value.Keypoints
    const len = #keypoints

    if schema.maxKeypoints and len > schema.maxKeypoints then
        return function()
            return `too many keypoints. maximum allowed keypoint count is {schema.maxKeypoints}`
        end
    end

    if schema.minKeypoints and len < schema.minKeypoints then
        return function()
            return `too few keypoints. minimum allowed keypoint count is {schema.minKeypoints}`
        end
    end

    if schema.strictKeypointOrder then
        -- 아래 규칙들은 엔진이 생성 시점에 이미 강제하지만, 명시적으로 켜졌을 때만 다시 확인한다
        if len < 2 then
            return function()
                return `color sequence must have at least 2 keypoints`
            end
        end

        if keypoints[1].Time ~= 0 then
            return function()
                return `first keypoint time must be 0`
            end
        end

        if keypoints[len].Time ~= 1 then
            return function()
                return `last keypoint time must be 1`
            end
        end

        for index = 2, len do
            if keypoints[index].Time < keypoints[index - 1].Time then
                return function()
                    return `keypoint times must be in non-decreasing order, but keypoint {index} has a smaller time than keypoint {index - 1}`
                end
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("ColorSequence", ColorSequence, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
