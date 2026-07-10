--!strict

const SchemaFactory = require("./base")

-- Generic 으로 singleton 을 받아 { [TypeName]: FactoryFunction } 하는 것을 시도하였으나,
-- 이는 프로퍼티가 아닌 인덱서로 취급됨.

export type TypeDef<FactoryFunction> = {
    typeName: string,
    factoryFunc: FactoryFunction,
    runtimeTypeChecker: (schema: any, value: any) -> (() -> string)?,
    runtimeConstraintChecker: (schema: any, value: any) -> (() -> string)?,
    luauBuilder: (schema: any) -> string,
    formatter: (schema: any) -> string,
    canBeNil: (schema: any) -> boolean,
}
export type TypeNamespaceInternal = {
    _runtimeTypeChecker: { [string]: (any, any) -> (() -> string)? },
    _runtimeConstraintChecker: { [string]: (any, any) -> (() -> string)? },
    _luauBuilder: { [string]: (any) -> string },
    _formatter: { [string]: (any) -> string },
    _canBeNil: { [string]: (any) -> boolean },
}
export type TypeNamespace = {
    runtimeTypeCheck: (self: TypeNamespace, schema: SchemaFactory.TSchema, value: any) -> (() -> string)?,
    runtimeConstraintCheck: (self: TypeNamespace, schema: SchemaFactory.TSchema, value: any) -> (() -> string)?,
    luauBuild: (self: TypeNamespace, schema: SchemaFactory.TSchema) -> string,
    format: (self: TypeNamespace, schema: SchemaFactory.TSchema) -> string,
    canBeNil: (self: TypeNamespace, schema: any) -> boolean,
    registerType: <FactoryFunction>(ns: TypeNamespace, typeDef: TypeDef<FactoryFunction>) -> TypeNamespace,
}

const function runtimeTypeCheck(self: TypeNamespace, schema: SchemaFactory.TSchema, value: any): (() -> string)?
    const checker = (self :: TypeNamespaceInternal)._runtimeTypeChecker[schema.tag]
    if not checker then
        error(`Type schema '{schema.tag}' does not exist in this type namespace`)
    end
    return checker(schema, value)
end

const function runtimeConstraintCheck(self: TypeNamespace, schema: SchemaFactory.TSchema, value: any): (() -> string)?
    const checker = (self :: TypeNamespaceInternal)._runtimeConstraintChecker[schema.tag]
    if not checker then
        error(`Type schema '{schema.tag}' does not exist in this type namespace`)
    end
    return checker(schema, value)
end

const function luauBuild(self: TypeNamespace, schema: SchemaFactory.TSchema): string
    const builder = (self :: TypeNamespaceInternal)._luauBuilder[schema.tag]
    if not builder then
        error(`Type schema '{schema.tag}' does not exist in this type namespace`)
    end
    return builder(schema)
end

const function format(self: TypeNamespace, schema: SchemaFactory.TSchema): string
    const formatter = (self :: TypeNamespaceInternal)._formatter[schema.tag]
    if not formatter then
        error(`Type schema '{schema.tag}' does not exist in this type namespace`)
    end
    return formatter(schema)
end

const function canBeNil(self: TypeNamespace, schema: SchemaFactory.TSchema): boolean
    const check = (self :: TypeNamespaceInternal)._canBeNil[schema.tag]
    if not check then
        error(`Type schema '{schema.tag}' does not exist in this type namespace`)
    end
    return check(schema)
end

const function registerType<FactoryFunction>(ns: TypeNamespace, typeDef: TypeDef<FactoryFunction>): TypeNamespace
    const nsInternal = ns :: TypeNamespaceInternal
    (ns :: any)[typeDef.typeName] = typeDef.factoryFunc
    nsInternal._luauBuilder[typeDef.typeName] = typeDef.luauBuilder
    nsInternal._runtimeTypeChecker[typeDef.typeName] = typeDef.runtimeTypeChecker
    nsInternal._runtimeConstraintChecker[typeDef.typeName] = typeDef.runtimeConstraintChecker
    nsInternal._formatter[typeDef.typeName] = typeDef.formatter
    nsInternal._canBeNil[typeDef.typeName] = typeDef.canBeNil
    return ns
end

const function newNamespace(): TypeNamespace
    return {
        _runtimeTypeChecker = {},
        _runtimeConstraintChecker = {},
        _luauBuilder = {},
        _formatter = {},
        _canBeNil = {},
        runtimeTypeCheck = runtimeTypeCheck,
        runtimeConstraintCheck = runtimeConstraintCheck,
        luauBuild = luauBuild,
        format = format,
        registerType = registerType,
        canBeNil = canBeNil,
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
