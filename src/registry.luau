--!strict

const Base = require("./base")

-- Generic 으로 singleton 을 받아 { [TypeName]: FactoryFunction } 하는 것을 시도하였으나,
-- 이는 프로퍼티가 아닌 인덱서로 취급됨.

export type TypeNamespaceInternal = {
    _types: { [string]: Base.TypeDef<any> },
}
export type TypeNamespace = {
    runtimeTypeCheck: (self: TypeNamespace, schema: Base.TSchema, value: any) -> (() -> string)?,
    runtimeConstraintCheck: (self: TypeNamespace, schema: Base.TSchema, value: any) -> (() -> string)?,
    luauBuild: (self: TypeNamespace, schema: Base.TSchema) -> string,
    format: (self: TypeNamespace, schema: Base.TSchema) -> string,
    canBeNil: (self: TypeNamespace, schema: Base.TSchema) -> boolean,
    inspectInner: (self: TypeNamespace, schema: Base.TSchema) -> { Base.TSchema }?,
    registerType: <FactoryFunction>(ns: TypeNamespace, typeDef: Base.TypeDef<FactoryFunction>) -> TypeNamespace,
    clone: (self: TypeNamespace) -> TypeNamespace,
}

const function getTypeDef(self: TypeNamespace, tag: string): Base.TypeDef<any>
    const def = (self :: TypeNamespaceInternal)._types[tag]
    if not def then
        error(`Type schema '{tag}' does not exist in this type namespace`)
    end
    return def
end

-- value 가 스키마의 타입과 비교해 올바른 타입을 가지는지 확인합니다. 만약 예상된 결과가 아니라면
-- 문자열을 출력하는 익명함수를 내보냅니다. 이는 union 등 다중 타입 구조에서 try match 같은 형태로
-- 일치하는 타입을 하나 찾아야할 때, 내부 요소에 대해 nil 이 반환되는 스키마를 찾는 용도로 사용할 수
-- 있습니다.
const function runtimeTypeCheck(self: TypeNamespace, schema: Base.TSchema, value: any): (() -> string)?
    return getTypeDef(self, schema.tag).runtimeTypeChecker(schema, value)
end

-- 런타임 제약 조건 (TArray의 길이, TString의 길이 등)이 성립하는지 유무를 검사합니다. value 는 이미
-- 정확한 런타임 타입을 가질 것을 기대합니다.
-- 이는 루아우 타입이 행하는 이상의 동작을 격리합니다. 문자열 길이 확인의 경우에도, TString | TString
-- 구조가 실 루아우에서는 항상 선행 TString 이 선택될 것입니다. 따라서 타입 선택 구조에서
-- 런타임 제약 조건은 사용되지 않음을 시사합니다.
const function runtimeConstraintCheck(self: TypeNamespace, schema: Base.TSchema, value: any): (() -> string)?
    return getTypeDef(self, schema.tag).runtimeConstraintChecker(schema, value)
end

-- 실제 루아우에서 사용되는 타입을 문자열로 빌드합니다
const function luauBuild(self: TypeNamespace, schema: Base.TSchema): string
    return getTypeDef(self, schema.tag).luauBuilder(schema)
end

-- 사람이 읽기 편한 형식으로 스키마를 문자열화 합니다. 오류 로깅, 디버깅에 사용될 수 있습니다
const function format(self: TypeNamespace, schema: Base.TSchema): string
    return getTypeDef(self, schema.tag).formatter(schema)
end

-- Union, default, optional 등의 타입에 대해 내부 상황에 따른 nil 수용 가능 여부를 확인합니다
-- Object 등에서 해당 필드가 required 인지 검사하는데 사용합니다
const function canBeNil(self: TypeNamespace, schema: Base.TSchema): boolean
    return getTypeDef(self, schema.tag).canBeNil(schema)
end

-- 스키마가 품은 내부적 요소 (object props, array inner, ...) 등을 내보냅니다.
-- 각 타입 요소를 collect 하여 최종 문서 또는 타입 선언을 생성하는데 필수적입니다.
const function inspectInner(self: TypeNamespace, schema: Base.TSchema): { Base.TSchema }?
    return getTypeDef(self, schema.tag).inspectInner(schema)
end

const function registerType<FactoryFunction>(self: TypeNamespace, typeDef: Base.TypeDef<FactoryFunction>): TypeNamespace
    const nsInternal = self :: TypeNamespaceInternal
    (self :: any)[typeDef.typeName] = typeDef.factoryFunc
    nsInternal._types[typeDef.typeName] = typeDef
    return self
end

const function clone(self: TypeNamespace): TypeNamespace
    const cloned = table.clone(self)
    const nsInternal = cloned :: TypeNamespaceInternal
    nsInternal._types = table.clone(nsInternal._types)
    return cloned
end

const function newNamespace(): TypeNamespace
    return {
        _types = {},
        runtimeTypeCheck = runtimeTypeCheck,
        runtimeConstraintCheck = runtimeConstraintCheck,
        luauBuild = luauBuild,
        format = format,
        registerType = registerType,
        canBeNil = canBeNil,
        inspectInner = inspectInner,
        clone = clone,
    }
end

const defaultUntypedNamespace = newNamespace()

return {
    newNamespace = newNamespace,
    registerType = registerType,
    defaultUntypedNamespace = defaultUntypedNamespace,
    runtimeTypeCheck = runtimeTypeCheck,
    runtimeConstraintCheck = runtimeConstraintCheck,
    luauBuild = luauBuild,
    format = format,
    canBeNil = canBeNil,
}
