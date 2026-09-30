--!strict

-- src/registry.luau (TypeNamespace) 직접 단위 테스트. 스키마 테스트는 전부 기본 네임스페이스만 거치므로,
-- 여기서는 newNamespace/clone/registerType 으로 만든 네임스페이스가 서로 독립적인지와 조회 실패 시의
-- 에러, 그리고 "재귀는 항상 기본 네임스페이스" 라는 알려진 한계를 확인한다.

const Base = require("../src/base")
const Helper = require("./helper")
const Registry = require("../src/registry")
const Type = require("../src")

-- 테스트 전용 스키마 타입. 문자열 "foo" 만 받는다. 필수 훅만 넘기므로 나머지 훅은 TypeDefFactory 기본값이다.
type TFoo = Base.TSchema
const function Foo(): TFoo
    return Base.SchemaFactory<<TFoo>>("Foo", nil, {})
end
const FooDef = Base.TypeDefFactory("Foo", Foo, {
    runtimeTypeChecker = function(_schema: TFoo, value: any): (() -> string)?
        if value == "foo" then
            return nil
        end
        return function()
            return "foo expected"
        end
    end,
    luauBuilder = function(_schema: TFoo): string
        return '"foo"'
    end,
    formatter = function(_schema: TFoo): string
        return "TFoo"
    end,
})

----------------------------------------------------------------------------------------------------
-- 기본 네임스페이스
----------------------------------------------------------------------------------------------------

-- 공개 진입점(src/init.luau)이 돌려주는 것은 registry 의 기본 네임스페이스 그 자체다.
-- 컨테이너 스키마들이 재귀할 때 require 하는 것도 이 객체이므로 둘이 달라지면 안 된다.
Helper.expectTrue(Type == Registry.defaultUntypedNamespace, "Type should be the default untyped namespace")
Helper.expectEqual(Type.namespaceName, "DefaultNamespace")

-- 등록된 모든 타입은 같은 이름으로 팩토리가 노출되어 있어야 한다
-- (registerType 이 _types 와 팩토리 필드를 항상 같이 갱신하는지 확인)
const defaultTypes = (Type :: any)._types :: { [string]: Base.TypeDef<any> }
local registeredCount = 0
for typeName, def in defaultTypes do
    registeredCount += 1
    Helper.expectEqual(def.typeName, typeName)
    Helper.expectTrue(
        (Type :: any)[typeName] == def.factoryFunc,
        `Type.{typeName} should be the factory function of the registered type`
    )
end
Helper.expectTrue(registeredCount > 0, "default namespace should have registered types")

----------------------------------------------------------------------------------------------------
-- newNamespace / registerType
----------------------------------------------------------------------------------------------------

const empty = Registry.newNamespace("Empty")
Helper.expectEqual(empty.namespaceName, "Empty")
-- 조회 실패는 클로저가 아니라 즉시 error() 로 알린다. tag 와 네임스페이스 이름이 모두 메시지에 나와야 한다
Helper.expectError(function()
    empty:luauBuild(Type.Number())
end, "type schema 'Number' does not exist in this type namespace 'Empty'")
Helper.expectError(function()
    empty:runtimeTypeCheck(Type.Number(), 1)
end, "type schema 'Number' does not exist in this type namespace 'Empty'")
-- 스키마가 아닌 값을 넘기면 tag 가 nil 로 조회된다
Helper.expectError(function()
    Type:luauBuild({} :: any)
end, "type schema 'nil' does not exist in this type namespace 'DefaultNamespace'")

-- registerType 은 체이닝을 위해 자기 자신을 돌려주고, 팩토리를 타입 이름으로 노출한다
const fooNamespace = Registry.newNamespace("FooNamespace")
Helper.expectTrue(fooNamespace:registerType(FooDef) == fooNamespace, "registerType should return the namespace itself")
Helper.expectTrue((fooNamespace :: any).Foo == Foo, "registerType should expose the factory function")

-- 모든 훅이 등록된 TypeDef 로 디스패치된다. 넘기지 않은 훅은 TypeDefFactory 기본값을 따른다
const foo = Foo()
Helper.expectOk(fooNamespace:runtimeTypeCheck(foo, "foo"))
Helper.expectFail(fooNamespace:runtimeTypeCheck(foo, "bar"), "foo expected")
Helper.expectEqual(fooNamespace:luauBuild(foo), '"foo"')
Helper.expectEqual(fooNamespace:format(foo), "TFoo")
Helper.expectOk(fooNamespace:runtimeConstraintCheck(foo, "foo"))
Helper.expectEqual(fooNamespace:canBeNil(foo), false)
Helper.expectEqual(fooNamespace:inspectInner(foo), nil)

-- 다른 네임스페이스에 등록한 타입은 기본 네임스페이스에 새지 않는다
Helper.expectEqual((Type :: any).Foo, nil)
Helper.expectEqual(defaultTypes.Foo, nil)

----------------------------------------------------------------------------------------------------
-- clone
----------------------------------------------------------------------------------------------------

const custom = Type:clone("Custom")
Helper.expectEqual(custom.namespaceName, "Custom")
-- 원본의 이름은 그대로다
Helper.expectEqual(Type.namespaceName, "DefaultNamespace")

-- 복제본은 원본의 모든 타입과 팩토리(Tuple 같은 추가 필드 포함)를 가진 채로 시작한다
for typeName, def in defaultTypes do
    Helper.expectTrue((custom :: any)[typeName] == def.factoryFunc, `clone should keep factory '{typeName}'`)
end
Helper.expectTrue((custom :: any).Tuple == (Type :: any).Tuple, "clone should keep extra fields such as Tuple")
Helper.expectEqual(custom:luauBuild(Type.Number()), "number")
Helper.expectFail(custom:runtimeTypeCheck(Type.Number(), "x"), "number expected, but got string")

-- 복제본에 타입을 등록해도 원본은 오염되지 않는다 (_types 테이블이 따로 복제되는지)
custom:registerType(FooDef)
Helper.expectEqual(custom:luauBuild(foo), '"foo"')
Helper.expectEqual((Type :: any).Foo, nil)
Helper.expectError(function()
    Type:luauBuild(foo)
end, "type schema 'Foo' does not exist in this type namespace 'DefaultNamespace'")

-- 반대로 복제 이후 원본에 등록한 타입은 복제본에 나타나지 않는다. 기본 네임스페이스를 건드리지 않기 위해
-- 원본 역할도 새 네임스페이스로 한다
const original = Registry.newNamespace("Original")
const snapshot = original:clone("Snapshot")
original:registerType(FooDef)
Helper.expectEqual((snapshot :: any).Foo, nil)
Helper.expectError(function()
    snapshot:luauBuild(foo)
end, "type schema 'Foo' does not exist in this type namespace 'Snapshot'")

-- 복제본에서 기존 타입을 같은 이름으로 덮어써도 원본의 정의는 그대로다
const overridden = Type:clone("Overridden")
overridden:registerType(Base.TypeDefFactory("Number", Type.Number, {
    runtimeTypeChecker = function(_schema: any, _value: any): (() -> string)?
        return nil
    end,
    luauBuilder = function(_schema: any): string
        return "OverriddenNumber"
    end,
    formatter = function(_schema: any): string
        return "TOverriddenNumber"
    end,
}))
Helper.expectEqual(overridden:luauBuild(Type.Number()), "OverriddenNumber")
Helper.expectEqual(Type:luauBuild(Type.Number()), "number")

----------------------------------------------------------------------------------------------------
-- 알려진 한계: 컨테이너의 재귀 호출은 항상 기본 네임스페이스로 간다
----------------------------------------------------------------------------------------------------

-- 컨테이너 스키마 모듈은 내부 스키마를 defaultUntypedNamespace 로 직접 재귀한다 (packages/tbox/CLAUDE.md
-- "네임스페이스" 절). 그래서 커스텀 네임스페이스는 최상위 호출에만 영향을 준다. 이 한계를 고치면
-- (훅에 네임스페이스를 넘기는 리팩터) 아래 기대값을 "복제본의 정의가 쓰인다" 로 바꿔야 한다.

-- 복제본에만 있는 타입을 컨테이너 안에 넣으면, 복제본에서 호출해도 기본 네임스페이스에서 찾다가 실패한다
Helper.expectError(function()
    custom:luauBuild(Type.Array(foo))
end, "type schema 'Foo' does not exist in this type namespace 'DefaultNamespace'")

-- 덮어쓴 정의도 최상위에서만 쓰이고, 컨테이너 안쪽은 기본 정의를 따른다
Helper.expectEqual(overridden:luauBuild(Type.Array(Type.Number())), "{number}")

return true
