--!strict

-- test/schema/roblox/enum.luau 는 음성 경로만 볼 수 있었다. 여기서는 실제 Enum 값으로 양성 경로를 확인한다.
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

const schema = Type.Enum()

Helper.expectOk(Common.check(schema, Enum.Material))
Helper.expectOk(Common.check(schema, Enum.KeyCode))
Helper.expectFail(Type:runtimeTypeCheck(schema, 123), "Enum expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(schema, "Material"), "Enum expected, but got string")
-- 전역 Enum 컨테이너(typeof "Enums")와 개별 EnumItem 은 Enum 이 아니다
Helper.expectFail(Type:runtimeTypeCheck(schema, Enum), "Enum expected, but got Enums")
Helper.expectFail(Type:runtimeTypeCheck(schema, Enum.Material.Plastic), "Enum expected, but got EnumItem")

Helper.expectEqual(Type:luauBuild(schema), "Enum")
Helper.expectEqual(Type:format(schema), "TEnum")

return true
