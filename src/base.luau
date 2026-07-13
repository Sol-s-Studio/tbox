--!strict

-- TSchema: InnerType<?> 을 성립
export type TSchema = {
    id: string?,
    description: string?,
    title: string?,
    tag: string,
}
export type TSchemaOptions = {
    id: string?,
    description: string?,
    title: string?,
}

-- 스키마의 기본 정의, tag와 id 등을 초기화합니다
const function SchemaFactory<Schema, Base>(tag: string, options: TSchemaOptions?, base: Base): Schema
    options = options or ({} :: TSchemaOptions)
    const anyBase = base :: any
    anyBase.tag = tag
    anyBase.id = options.id
    anyBase.description = options.description
    anyBase.title = options.title
    return anyBase :: Schema
end

export type TypeDef<FactoryFunction> = {
    typeName: string,
    factoryFunc: FactoryFunction,
    runtimeTypeChecker: (schema: any, value: any) -> (() -> string)?,
    runtimeConstraintChecker: (schema: any, value: any) -> (() -> string)?,
    luauBuilder: (schema: any) -> string,
    formatter: (schema: any) -> string,
    canBeNil: (schema: any) -> boolean,
    inspectInner: (schema: any) -> { TSchema }?,
}

-- 타입에 대한 정의를 초기화합니다
const function TypeDefFactory<FactoryFunction>(
    typeName: string,
    factoryFunc: FactoryFunction,
    options: {
        runtimeTypeChecker: (schema: any, value: any) -> (() -> string)?,
        runtimeConstraintChecker: ((schema: any, value: any) -> (() -> string)?)?,
        luauBuilder: (schema: any) -> string,
        formatter: (schema: any) -> string,
        canBeNil: ((schema: any) -> boolean)?,
        inspectInner: ((schema: any) -> { TSchema }?)?,
    }
): TypeDef<FactoryFunction>
    return {
        typeName = typeName,
        factoryFunc = factoryFunc,
        runtimeTypeChecker = options.runtimeTypeChecker,
        runtimeConstraintChecker = options.runtimeConstraintChecker or function()
            return nil
        end,
        luauBuilder = options.luauBuilder,
        formatter = options.formatter,
        canBeNil = options.canBeNil or function()
            return false
        end,
        inspectInner = options.inspectInner or function()
            return nil
        end,
    }
end

return {
    SchemaFactory = SchemaFactory,
    TypeDefFactory = TypeDefFactory,
}
