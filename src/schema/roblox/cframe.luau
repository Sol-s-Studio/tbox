--!strict

const Base = require("../../base")
const Types = require("../../types")

-- 정규직교 여부 판정 시 기본으로 사용하는 허용 오차
const DEFAULT_ORTHONORMAL_EPSILON = 1e-5

export type TCFrame = {
    positionMin: Vector3?,
    positionMax: Vector3?,
    minPositionMagnitude: number?,
    maxPositionMagnitude: number?,
    notNan: boolean?,
    orthonormalOnly: boolean?,
    orthonormalEpsilon: number?,
    rightHandedOnly: boolean?,
} & Base.TSchema & Types.InnerType<CFrame> & Types.NamedType<"CFrame">
export type TCFrameOptions = Types.Merge<{
    positionMin: Vector3?,
    positionMax: Vector3?,
    minPositionMagnitude: number?,
    maxPositionMagnitude: number?,
    notNan: boolean?,
    orthonormalOnly: boolean?,
    orthonormalEpsilon: number?,
    rightHandedOnly: boolean?,
}, Base.TSchemaOptions>

const function CFrameType(options: TCFrameOptions?): TCFrame
    options = options or ({} :: TCFrameOptions)
    return Base.SchemaFactory<<TCFrame>>("CFrame", options, {
        positionMin = options.positionMin,
        positionMax = options.positionMax,
        minPositionMagnitude = options.minPositionMagnitude,
        maxPositionMagnitude = options.maxPositionMagnitude,
        notNan = options.notNan,
        orthonormalOnly = options.orthonormalOnly,
        orthonormalEpsilon = options.orthonormalEpsilon,
        rightHandedOnly = options.rightHandedOnly,
    })
end

const function luauBuilder(_schema: TCFrame): string
    return "CFrame"
end

const function formatter(_schema: TCFrame): string
    return "TCFrame"
end

const function runtimeTypeChecker(_schema: TCFrame, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "CFrame" then
        return function()
            return `CFrame expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TCFrame, value: CFrame): (() -> string)?
    -- CFrame 은 성분이 12개(위치 3 + 회전 9)라 에러 메시지에 전부 노출하면 가독성이 떨어진다.
    -- 위치(Position) 관련 실패만 사람이 읽기 좋은 형태로 노출하고, 회전 실패는 별도 문구로 알린다.
    const position = value.Position

    if schema.notNan then
        if position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z then
            return function()
                return `nan is not allowed in cframe position`
            end
        end
    end

    const positionMax = schema.positionMax
    if positionMax then
        if position.X > positionMax.X then
            return function()
                return `position x value too big. maximum allowed x value is {positionMax.X}`
            end
        elseif position.Y > positionMax.Y then
            return function()
                return `position y value too big. maximum allowed y value is {positionMax.Y}`
            end
        elseif position.Z > positionMax.Z then
            return function()
                return `position z value too big. maximum allowed z value is {positionMax.Z}`
            end
        end
    end

    const positionMin = schema.positionMin
    if positionMin then
        if position.X < positionMin.X then
            return function()
                return `position x value too small. minimum allowed x value is {positionMin.X}`
            end
        elseif position.Y < positionMin.Y then
            return function()
                return `position y value too small. minimum allowed y value is {positionMin.Y}`
            end
        elseif position.Z < positionMin.Z then
            return function()
                return `position z value too small. minimum allowed z value is {positionMin.Z}`
            end
        end
    end

    -- 필요할 때만 계산하는 지연 계산 패턴 (vector.luau 참고)
    local positionMagnitude: number?

    if schema.maxPositionMagnitude then
        if positionMagnitude == nil then
            positionMagnitude = position.Magnitude
        end
        if (positionMagnitude :: number) > schema.maxPositionMagnitude then
            return function()
                return `position too far from origin. maximum allowed magnitude is {schema.maxPositionMagnitude}`
            end
        end
    end

    if schema.minPositionMagnitude then
        if positionMagnitude == nil then
            positionMagnitude = position.Magnitude
        end
        if (positionMagnitude :: number) < schema.minPositionMagnitude then
            return function()
                return `position too close to origin. minimum allowed magnitude is {schema.minPositionMagnitude}`
            end
        end
    end

    if schema.orthonormalOnly then
        const rotation = value.Rotation
        const epsilon = schema.orthonormalEpsilon or DEFAULT_ORTHONORMAL_EPSILON
        if not rotation:FuzzyEq(rotation:Orthonormalize(), epsilon) then
            return function()
                return `cframe rotation must be orthonormal`
            end
        end
    end

    -- 손잡이(handedness) 검사. 정규직교성과는 별개의 결함이라 옵션을 나눈다.
    -- 왼손 좌표계(행렬식 -1)는 회전이 아니라 회전+거울반사이며, 어떤 물리적 회전으로도
    -- 도달할 수 없다. 누적 오차로는 부호가 뒤집히지 않으므로 이것이 나왔다면 조작되었거나
    -- 손상된 입력(fromMatrix 4인자 / 12성분 생성자 경로)이다.
    -- 특히 Orthonormalize() 는 그람-슈미트라 손잡이를 보존하므로 이 결함을 고쳐주지 못한다.
    if schema.rightHandedOnly then
        if value.XVector:Cross(value.YVector):Dot(value.ZVector) <= 0 then
            return function()
                return `cframe rotation must be right-handed. mirrored rotation is not allowed`
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("CFrame", CFrameType, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
