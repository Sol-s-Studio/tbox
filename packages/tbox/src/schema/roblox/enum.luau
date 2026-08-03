--!strict

-- 전역 Enum 컨테이너 자체(예: Enum.Material)를 값으로 받는 드문 경우를 위한 스키마.
-- 참고: 전역 `Enum` (모든 Enum 을 담은 컨테이너)의 typeof 는 "Enums" 로 별개 타입이며,
-- 이 스키마가 다루는 대상은 typeof 가 "Enum" 인 개별 Enum(Enum.Material 등)이다.
const Base = require("../../base")
const Types = require("../../types")

export type TEnum = {} & Base.TSchema & Types.InnerType<Enum> & Types.NamedType<"Enum">
export type TEnumOptions = Types.Merge<{}, Base.TSchemaOptions>

const function Enum(options: TEnumOptions?): TEnum
    options = options or ({} :: TEnumOptions)
    return Base.SchemaFactory<<TEnum>>("Enum", options, {})
end

const function luauBuilder(_schema: TEnum): string
    return "Enum"
end

const function formatter(_schema: TEnum): string
    return "TEnum"
end

const function runtimeTypeChecker(_schema: TEnum, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "Enum" then
        return function()
            return `Enum expected, but got {ty}`
        end
    end
    return nil
end

return Base.TypeDefFactory("Enum", Enum, {
    runtimeTypeChecker = runtimeTypeChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
