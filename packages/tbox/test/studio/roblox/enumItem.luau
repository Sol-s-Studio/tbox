--!strict

-- test/schema/roblox/enumItem.luau 는 mock 문자열로 enumType 을 흉내냈고, 타입 검사 안의 EnumType 판별 분기는
-- 도달할 수 없었다. 여기서는 실제 Enum / EnumItem 으로 그 분기와 allowedItems 를 확인한다.
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

const material = Type.EnumItem(Enum.Material)

-- tostring(Enum.Material) == "Material" 이라 실제 Roblox 타입 이름과 정확히 일치한다
Helper.expectEqual(Type:luauBuild(material), "Enum.Material")
Helper.expectEqual(Type:format(material), "TEnumItem<Enum.Material>")
Helper.expectParsableType(Type:luauBuild(material))

Helper.expectOk(Common.check(material, Enum.Material.Plastic))
Helper.expectOk(Common.check(material, Enum.Material.Wood))
Helper.expectFail(Type:runtimeTypeCheck(material, 123), "EnumItem expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(material, "Plastic"), "EnumItem expected, but got string")
Helper.expectFail(Type:runtimeTypeCheck(material, Enum.Material), "EnumItem expected, but got Enum")

-- 다른 Enum 의 항목은 타입 검사 단계에서 거부된다 (EnumType 비교)
Helper.expectFail(
    Type:runtimeTypeCheck(material, Enum.KeyCode.A),
    "EnumItem of Enum.Material expected, but got Enum.KeyCode.A"
)
-- 같은 이름(Plastic)이더라도 다른 Enum 이면 거부된다
Helper.expectFail(
    Type:runtimeTypeCheck(material, Enum.PartType.Ball),
    "EnumItem of Enum.Material expected, but got Enum.PartType.Ball"
)

-- enumType 을 생략하면 어떤 EnumItem 이든 받는다
const anyEnumItem = Type.EnumItem(nil)
Helper.expectEqual(Type:luauBuild(anyEnumItem), "EnumItem")
Helper.expectOk(Common.check(anyEnumItem, Enum.Material.Plastic))
Helper.expectOk(Common.check(anyEnumItem, Enum.KeyCode.A))

-- allowedItems 는 제약 검사다. 메시지는 tostring(EnumItem) == "Enum.Material.Plastic" 형태로 나온다
const restricted = Type.EnumItem(Enum.Material, { allowedItems = { Enum.Material.Plastic, Enum.Material.Wood } })
Helper.expectOk(Common.check(restricted, Enum.Material.Plastic))
Helper.expectOk(Common.check(restricted, Enum.Material.Wood))
Helper.expectFail(
    Common.check(restricted, Enum.Material.Metal),
    "EnumItem must be one of [Enum.Material.Plastic, Enum.Material.Wood], but got Enum.Material.Metal"
)
-- FromName / FromValue 로 다시 찾은 항목도 같은 값으로 비교된다 (EnumItem 은 == 로 동일성 비교 가능)
Helper.expectOk(Common.check(restricted, Enum.Material:FromName("Wood")))
Helper.expectOk(Common.check(restricted, Enum.Material:FromValue(Enum.Material.Plastic.Value)))

-- 유니온에서 서로 다른 Enum 을 분기로 고를 수 있다
const materialOrKey = Type.Union(Type.Tuple(Type.EnumItem(Enum.Material), Type.EnumItem(Enum.KeyCode)))
Helper.expectOk(Common.check(materialOrKey, Enum.Material.Plastic))
Helper.expectOk(Common.check(materialOrKey, Enum.KeyCode.A))
Helper.expectFail(
    Type:runtimeTypeCheck(materialOrKey, Enum.PartType.Ball),
    "union value check failed. value did not match any of the union members.\n"
        .. "  branch 1: EnumItem of Enum.Material expected, but got Enum.PartType.Ball\n"
        .. "  branch 2: EnumItem of Enum.KeyCode expected, but got Enum.PartType.Ball"
)

return true
