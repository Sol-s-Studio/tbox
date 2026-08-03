--!strict

const Type = require("../../src")
const Helper = require("../helper")

-- Unsafe 는 런타임 검사를 전혀 하지 않고 항상 통과한다 (정적 타입만 명시적 타입 인자로 부여)
const schema = Type.Unsafe<<number>>({ luauType = "number" })
Helper.expectOk(Type:runtimeTypeCheck(schema, "not a number at all"))
Helper.expectOk(Type:runtimeTypeCheck(schema, nil))

Helper.expectEqual(Type:luauBuild(schema), "number")
Helper.expectEqual(Type:format(schema), "TUnsafe<number>")

-- luauType 을 생략하면 "unknown", canBeNil 은 false 가 기본값이다
const bare = Type.Unsafe()
Helper.expectEqual(Type:luauBuild(bare), "unknown")
Helper.expectTrue(not Type:canBeNil(bare), "canBeNil should default to false")

const nilable = Type.Unsafe({ canBeNil = true })
Helper.expectTrue(Type:canBeNil(nilable), "canBeNil should reflect the option")

return true
