--!strict

-- EnumItem 도 Instance 와 마찬가지로 정적 타입을 제네릭 인자로 받는다
-- (src/schema/unsafe.luau 의 TUnsafe<T> 패턴 참고).
-- 예: Type.EnumItem<<Enum.Material>>(Enum.Material)
const Base = require("../../base")
const Types = require("../../types")

export type TEnumItem<ItemType> =
    { enumType: any?, enumName: string?, allowedItems: { any }? }
    & Base.TSchema
    & Types.InnerType<ItemType>
    & Types.NamedType<"EnumItem">
export type TEnumItemOptions = Types.Merge<{ allowedItems: { any }? }, Base.TSchemaOptions>

const function EnumItem<ItemType>(enumType: any?, options: TEnumItemOptions?): TEnumItem<ItemType>
    options = options or ({} :: TEnumItemOptions)
    -- enumType 이 nil 이면 tostring 을 호출하지 않는다 (전역 Enum 없이도 로드 가능해야 한다)
    local enumName: string? = nil
    if enumType ~= nil then
        enumName = tostring(enumType)
    end
    return Base.SchemaFactory<<TEnumItem<ItemType>>>("EnumItem", options, {
        enumType = enumType,
        enumName = enumName,
        allowedItems = options.allowedItems,
    })
end

const function luauBuilder(schema: TEnumItem<any>): string
    -- tostring(Enum.Material) 은 "Material" 을 반환하므로 Enum. 접두사를 붙이면
    -- 정확한 Roblox 타입 이름(Enum.Material)이 된다
    if schema.enumName then
        return `Enum.{schema.enumName}`
    end
    return "EnumItem"
end

const function formatter(schema: TEnumItem<any>): string
    return `TEnumItem<{luauBuilder(schema)}>`
end

const function runtimeTypeChecker(schema: TEnumItem<any>, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "EnumItem" then
        return function()
            return `EnumItem expected, but got {ty}`
        end
    end

    -- 어느 Enum 에 속하는지는 타입 정보이므로 타입 검사 단계에서 판별한다
    if schema.enumType ~= nil and value.EnumType ~= schema.enumType then
        return function()
            return `EnumItem of {luauBuilder(schema)} expected, but got Enum.{tostring(value.EnumType)}.{value.Name}`
        end
    end

    return nil
end

const function runtimeConstraintChecker(schema: TEnumItem<any>, value: any): (() -> string)?
    -- value 는 이미 타입 검사를 통과했다고 가정한다
    if schema.allowedItems then
        for _, item in schema.allowedItems do
            if item == value then
                return nil
            end
        end
        return function()
            const names = table.create(#schema.allowedItems)
            for _, item in schema.allowedItems do
                table.insert(names, tostring(item))
            end
            return `EnumItem must be one of [{table.concat(names, ", ")}], but got {tostring(value)}`
        end
    end
    return nil
end

return Base.TypeDefFactory("EnumItem", EnumItem, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
