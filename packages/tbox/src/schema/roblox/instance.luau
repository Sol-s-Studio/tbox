--!strict

-- Instance 는 Roblox 클래스 계층을 그대로 반영하는 값이므로, 정적 타입은
-- src/schema/unsafe.luau 의 TUnsafe<T> 패턴처럼 제네릭 인자로 받는다.
-- 예: Type.Instance<<BasePart>>("BasePart")
const Base = require("../../base")
const Types = require("../../types")

export type TInstance<InstanceType> = {
    className: string,
    exactClassName: boolean?,
    nameMatch: string?,
    requiredChildren: { string }?,
} & Base.TSchema & Types.InnerType<InstanceType> & Types.NamedType<"Instance">
export type TInstanceOptions = Types.Merge<
    { exactClassName: boolean?, nameMatch: string?, requiredChildren: { string }? },
    Base.TSchemaOptions
>

const function Instance<InstanceType>(className: string?, options: TInstanceOptions?): TInstance<InstanceType>
    options = options or ({} :: TInstanceOptions)
    return Base.SchemaFactory<<TInstance<InstanceType>>>("Instance", options, {
        className = className or "Instance",
        exactClassName = options.exactClassName,
        nameMatch = options.nameMatch,
        requiredChildren = options.requiredChildren,
    })
end

const function luauBuilder(schema: TInstance<any>): string
    -- Roblox 에서는 클래스명이 곧 Luau 타입 이름이다 (Part, BasePart, Instance ...)
    return schema.className
end

const function formatter(schema: TInstance<any>): string
    return `TInstance<{schema.className}>`
end

const function runtimeTypeChecker(schema: TInstance<any>, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "Instance" then
        return function()
            return `Instance expected, but got {ty}`
        end
    end

    -- 클래스 판별은 유니온 분기 선택에도 쓰이므로 타입 검사 단계에 둔다.
    -- ClassName / IsA 는 모든 Instance 에 존재가 보장된 멤버이므로 그대로 접근해도 안전하다.
    -- (임의의 사용자 정의 프로퍼티는 존재하지 않으면 인덱싱 자체가 에러를 던지므로 접근하지 않는다.)
    if schema.exactClassName then
        if value.ClassName ~= schema.className then
            return function()
                return `Instance of class '{schema.className}' expected, but got '{value.ClassName}'`
            end
        end
    else
        if not value:IsA(schema.className) then
            return function()
                return `Instance of class '{schema.className}' (or subclass) expected, but got '{value.ClassName}'`
            end
        end
    end

    return nil
end

const function runtimeConstraintChecker(schema: TInstance<any>, value: any): (() -> string)?
    -- value 는 이미 타입 검사를 통과했다고 가정한다
    if schema.nameMatch and not string.match(value.Name, schema.nameMatch) then
        return function()
            return `Instance name '{value.Name}' does not match pattern '{schema.nameMatch}'`
        end
    end

    if schema.requiredChildren then
        for _, name in schema.requiredChildren do
            if not value:FindFirstChild(name) then
                return function()
                    return `Instance is missing required child '{name}'`
                end
            end
        end
    end

    return nil
end

return Base.TypeDefFactory("Instance", Instance, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
