--!strict

const Type = require("../../../src")
const Helper = require("../../helper")

-- typeof "Enum" 은 전역 Enum 컨테이너 자체(예: Enum.Material)를 가리키는 드문 경우다.
-- Enum 을 담는 전역 컨테이너("Enums" 타입)나 개별 EnumItem("EnumItem" 타입)과는 다르다.
Helper.expectFail(Type:runtimeTypeCheck(Type.Enum(), 123), "Enum expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(Type.Enum(), "Material"), "Enum expected, but got string")

Helper.expectEqual(Type:luauBuild(Type.Enum()), "Enum")
Helper.expectEqual(Type:format(Type.Enum()), "TEnum")

return true
