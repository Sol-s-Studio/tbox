--!strict

const Base = require("../../base")
const Types = require("../../types")

export type TNumberSequence = {
    minKeypoints: number?,
    maxKeypoints: number?,
    minValue: number?,
    maxValue: number?,
    maxEnvelope: number?,
    strictKeypointOrder: boolean?,
} & Base.TSchema & Types.InnerType<NumberSequence> & Types.NamedType<"NumberSequence">
export type TNumberSequenceOptions = Types.Merge<{
    minKeypoints: number?,
    maxKeypoints: number?,
    minValue: number?,
    maxValue: number?,
    maxEnvelope: number?,
    strictKeypointOrder: boolean?,
}, Base.TSchemaOptions>

const function NumberSequence(options: TNumberSequenceOptions?): TNumberSequence
    options = options or ({} :: TNumberSequenceOptions)
    return Base.SchemaFactory<<TNumberSequence>>("NumberSequence", options, {
        minKeypoints = options.minKeypoints,
        maxKeypoints = options.maxKeypoints,
        minValue = options.minValue,
        maxValue = options.maxValue,
        maxEnvelope = options.maxEnvelope,
        strictKeypointOrder = options.strictKeypointOrder,
    })
end

const function luauBuilder(_schema: TNumberSequence): string
    return "NumberSequence"
end

const function formatter(_schema: TNumberSequence): string
    return "TNumberSequence"
end

const function runtimeTypeChecker(_schema: TNumberSequence, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "NumberSequence" then
        return function()
            return `NumberSequence expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TNumberSequence, value: NumberSequence): (() -> string)?
    const keypoints = value.Keypoints
    const count = #keypoints

    if schema.maxKeypoints and count > schema.maxKeypoints then
        return function()
            return `NumberSequence has too many keypoints. maximum allowed count is {schema.maxKeypoints}`
        end
    end

    if schema.minKeypoints and count < schema.minKeypoints then
        return function()
            return `NumberSequence has too few keypoints. minimum allowed count is {schema.minKeypoints}`
        end
    end

    -- 최소 2개 / Time 비내림차순 / 첫 Time == 0 / 마지막 Time == 1 은 엔진이 생성 시점에
    -- 이미 강제하는 규칙이므로, 명시적으로 켰을 때만 검사한다
    if schema.strictKeypointOrder then
        if count < 2 then
            return function()
                return `NumberSequence must have at least 2 keypoints, but got {count}`
            end
        end

        if keypoints[1].Time ~= 0 then
            return function()
                return `NumberSequence first keypoint Time must be 0, but got {keypoints[1].Time}`
            end
        end

        if keypoints[count].Time ~= 1 then
            return function()
                return `NumberSequence last keypoint Time must be 1, but got {keypoints[count].Time}`
            end
        end

        for index = 2, count do
            if keypoints[index].Time < keypoints[index - 1].Time then
                return function()
                    return `NumberSequence keypoints must have non-decreasing Time, but keypoint {index} has Time {keypoints[index].Time} which is less than keypoint {index - 1}'s Time {keypoints[index - 1].Time}`
                end
            end
        end
    end

    for index = 1, count do
        const keypoint = keypoints[index]

        if schema.maxValue and keypoint.Value > schema.maxValue then
            return function()
                return `NumberSequence keypoint {index} Value too big. maximum allowed value is {schema.maxValue}`
            end
        end

        if schema.minValue and keypoint.Value < schema.minValue then
            return function()
                return `NumberSequence keypoint {index} Value too small. minimum allowed value is {schema.minValue}`
            end
        end

        if schema.maxEnvelope and keypoint.Envelope > schema.maxEnvelope then
            return function()
                return `NumberSequence keypoint {index} Envelope too big. maximum allowed value is {schema.maxEnvelope}`
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("NumberSequence", NumberSequence, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
