--!strict

-- src/base.luau 직접 단위 테스트. SchemaFactory 가 공통 필드를 어떻게 채우는지와, TypeDefFactory 가
-- 생략된 선택 훅에 어떤 기본값을 넣는지를 확인한다. 모든 스키마 타입이 이 두 함수 위에 올라가 있으므로
-- 여기서 기본값이 바뀌면 TObject 의 필수 필드 판정(canBeNil) 등 여러 곳의 동작이 함께 바뀐다.

const Base = require("../src/base")
const Helper = require("./helper")
const Type = require("../src")

----------------------------------------------------------------------------------------------------
-- SchemaFactory
----------------------------------------------------------------------------------------------------

-- base 테이블을 새로 만들지 않고 그대로 채워서 돌려준다
const baseTable = { extra = 1 }
const schema = Base.SchemaFactory<<any>>("Tag", { id = "id", title = "title", description = "description" }, baseTable)
Helper.expectTrue(schema == baseTable, "SchemaFactory should return the given base table")
Helper.expectEqual(schema.tag, "Tag")
Helper.expectEqual(schema.id, "id")
Helper.expectEqual(schema.title, "title")
Helper.expectEqual(schema.description, "description")
Helper.expectEqual(schema.extra, 1)

-- options 는 생략할 수 있고, 그때 공통 필드는 nil 이다
const bare = Base.SchemaFactory<<any>>("Tag", nil, {})
Helper.expectEqual(bare.tag, "Tag")
Helper.expectEqual(bare.id, nil)
Helper.expectEqual(bare.title, nil)
Helper.expectEqual(bare.description, nil)

-- 실제 스키마 팩토리들도 공통 옵션을 그대로 전달한다
const number = Type.Number({ id = "n", title = "Count", description = "how many" })
Helper.expectEqual(number.tag, "Number")
Helper.expectEqual(number.id, "n")
Helper.expectEqual(number.title, "Count")
Helper.expectEqual(number.description, "how many")

----------------------------------------------------------------------------------------------------
-- TypeDefFactory
----------------------------------------------------------------------------------------------------

const function factory() end
const function typeChecker(_schema: any, _value: any): (() -> string)?
    return nil
end
const function builder(_schema: any): string
    return "Built"
end
const function formatter(_schema: any): string
    return "TFormatted"
end

const def = Base.TypeDefFactory("Minimal", factory, {
    runtimeTypeChecker = typeChecker,
    luauBuilder = builder,
    formatter = formatter,
})
Helper.expectEqual(def.typeName, "Minimal")
Helper.expectTrue(def.factoryFunc == factory, "factoryFunc should be kept as is")
Helper.expectTrue(def.runtimeTypeChecker == typeChecker, "runtimeTypeChecker should be kept as is")
Helper.expectTrue(def.luauBuilder == builder, "luauBuilder should be kept as is")
Helper.expectTrue(def.formatter == formatter, "formatter should be kept as is")

-- 생략한 선택 훅의 기본값: 제약 없음, nil 불허, 내부 스키마 없음
Helper.expectOk(def.runtimeConstraintChecker({}, 1))
Helper.expectEqual(def.canBeNil({}), false)
Helper.expectEqual(def.inspectInner({}), nil)

-- 선택 훅을 넘기면 기본값 대신 그것을 쓴다
const function constraintChecker(_schema: any, _value: any): (() -> string)?
    return function()
        return "constraint failed"
    end
end
const full = Base.TypeDefFactory("Full", factory, {
    runtimeTypeChecker = typeChecker,
    runtimeConstraintChecker = constraintChecker,
    luauBuilder = builder,
    formatter = formatter,
    canBeNil = function(_schema: any): boolean
        return true
    end,
    inspectInner = function(_schema: any): { Base.TSchema }?
        return {}
    end,
})
Helper.expectFail(full.runtimeConstraintChecker({}, 1), "constraint failed")
Helper.expectEqual(full.canBeNil({}), true)
Helper.expectEqual(#(full.inspectInner({}) :: { Base.TSchema }), 0)

return true
