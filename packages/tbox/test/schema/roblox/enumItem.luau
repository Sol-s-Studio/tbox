--!strict

const Type = require("../../../src")
const Helper = require("../../helper")

-- 실사용 예: Type.EnumItem<<Enum.Material>>(Enum.Material). 여기서는 Roblox 전역이 없으므로
-- enumType 자리에 값 자체를 목(mock)으로 대신하고, 문자열 비교(EnumType ~= schema.enumType)만 검증한다.
const mockEnumType = "MockMaterial"
const schema = Type.EnumItem(mockEnumType)

Helper.expectFail(Type:runtimeTypeCheck(schema, 123), "EnumItem expected, but got number")
Helper.expectEqual(Type:luauBuild(schema), "Enum.MockMaterial")
Helper.expectEqual(Type:format(schema), "TEnumItem<Enum.MockMaterial>")

-- enumType 을 생략하면 tostring 을 호출하지 않는다 (전역 Enum 없이도 로드 가능해야 한다)
const anyEnumItem = Type.EnumItem(nil)
Helper.expectEqual(Type:luauBuild(anyEnumItem), "EnumItem")

const function mockEnumItem(enumType: string, name: string)
	return { EnumType = enumType, Name = name }
end

-- 주의: enumType 일치 여부는 runtimeTypeChecker 안에서 typeof(value) == "EnumItem" 을 먼저
-- 확인한 뒤에 비교된다. 목(mock) 테이블의 typeof 는 항상 "table" 이라 이 분기는 standalone luau
-- 에서 재현할 수 없다 (repo CLAUDE.md 참고). allowedItems 는 runtimeConstraintChecker 에 있고
-- typeof 를 보지 않으므로 여기서 직접 확인할 수 있다.
const plastic = mockEnumItem(mockEnumType, "Plastic")
const wood = mockEnumItem(mockEnumType, "Wood")
const restricted = Type.EnumItem(mockEnumType, { allowedItems = { plastic, wood } })

const metal = mockEnumItem(mockEnumType, "Metal")

Helper.expectOk(Type:runtimeConstraintCheck(restricted, plastic))
Helper.expectFail(
	Type:runtimeConstraintCheck(restricted, metal),
	`EnumItem must be one of [{tostring(plastic)}, {tostring(wood)}], but got {tostring(metal)}`
)

return true
